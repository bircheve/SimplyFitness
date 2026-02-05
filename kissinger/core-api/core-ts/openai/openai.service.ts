import { ChatCompletionRequestMessage, Configuration, CreateChatCompletionRequest, OpenAIApi } from 'openai';
import { responseSchema } from './workoutResponseSchema';
import Ajv, { ValidateFunction } from 'ajv';
import { Logger } from '@aws-lambda-powertools/logger';
import { Exercise, ExerciseSection } from '../data/model';
import { GenerateWorkoutEvent, SystemPrompt } from './systemPrompt';

export type GPTInputContent = {
  role: string;
  content: string;
};

export type GenerateWorkoutResponse = {
  completionId: string;
  workout: any;
  error?: Error;
  rawWorkout?: any;
  formattedWorkout?: any;
};

export type GenerateWorkoutContentResponse = {
  completionId: string;
  workout: any;
  error?: Error;
};

export type IsolateWorkoutRequest = {
  rawWorkout: string;
};

export type IsolateWorkoutResponse = {
  completionId: string;
  workout: string;
  error?: Error;
};

export type FormatWorkoutContentResponse = {
  completionId: string;
  workout: any;
  empty: boolean;
  error?: Error;
};

export type SelectBestWorkoutResponse = {
  completionId: string;
  workout: any;
  error?: Error;
};

export type AddExerciseRequest = {
  formattedWorkout: any;
  section: ExerciseSection;
}

export type AddExerciseResponse = {
  exercise: Exercise;
  error?: Error;
}

export type RemixExerciseRequest = {
  exercise: Exercise;
  section: ExerciseSection;
  workout: any;
  feedback: string;
}

export class OpenAIService {
  private gptModel: string;
  private openai: OpenAIApi;
  private schemaValidator: ValidateFunction;
  private logger: Logger;

  constructor(opts?: { apiKey?: string, logger?: Logger }) {
    this.gptModel = 'gpt-4-0613';
    this.openai = new OpenAIApi(
      new Configuration({ apiKey: opts?.apiKey ?? process.env.OPEN_AI_API_KEY }),
    );
    this.logger = opts?.logger ?? new Logger({ serviceName: 'OpenAIService' });
    this.schemaValidator = new Ajv().compile(responseSchema);
  }

  //content: {role: "user", content: string.}
  //History: an array of obj: {role: string, content: string}
  //create function: if we wanted multiple schemas we can define function somewhere else.
  public async generateWorkout(content: ChatCompletionRequestMessage[]): Promise<GenerateWorkoutResponse> {
    let response: GenerateWorkoutResponse = { workout: {}, completionId: '' };
    try {
      const completion = await this.openai.createChatCompletion({
        model: this.gptModel,
        messages: content,
      });
      const completionId = completion.data?.id;

      this.logger.info(`received generate response`, { ...completion.data?.usage, finishReason: completion.data?.choices[0]?.finish_reason });

      response.rawWorkout = completion.data?.choices[0].message?.content;

      return { ...response, workout: {}, completionId };
    } catch (error: any) {
      const { message, status, response } = error
      return { ...response, error: { message, status, data: response?.data } as unknown as Error };
    }
  }

  /*
  * Attempts to clean the raw workout text by removing any unnecessary text.
  */
  public async isolateWorkout({ rawWorkout }: IsolateWorkoutRequest): Promise<IsolateWorkoutResponse> {
    let response: IsolateWorkoutResponse = { workout: '', completionId: '' };
    const messages: ChatCompletionRequestMessage[] = [
      { role: 'system', content: 'You are an AI data formatter. Parse and extract only the workout details from the given workout text.' },
      { role: 'user', content: JSON.stringify(rawWorkout) }
    ];
    try {
      const completion = await this.openai.createChatCompletion({
        model: 'gpt-3.5-turbo-0613',
        messages,
      });
      const completionId = completion.data?.id;
      this.logger.info(`received isolate response`, { ...completion.data?.usage, finishReason: completion.data?.choices[0]?.finish_reason });

      return { ...response, workout: completion.data?.choices[0].message?.content ?? 'NOT_SET', completionId };
    } catch (error) {
      return { ...response, error: error as Error };
    }
  }

  /**
   * Attempts to format the given workout text into a JSON object that conforms to the workoutResponseSchema.
   */
  public async formatWorkout(rawWorkout: string, retryCount = 0): Promise<FormatWorkoutContentResponse> {
    const maxRetries = 3;

    let messages: ChatCompletionRequestMessage[] = [
      { role: 'system', content: `You are an AI data formatter. Parse the given workout text into a JSON object that conforms to the following JSON schema:\n${JSON.stringify(responseSchema)}\nEnsure the length of each 'exercises' array matches the 'Count' for each section in text.` },
      { role: 'user', content: rawWorkout }
    ]

    let response: FormatWorkoutContentResponse = { workout: {}, completionId: '', empty: false };
    let validJson = true;
    try {
      for (let attempt = 0; attempt < maxRetries; attempt++) {
        this.logger.info(`Formatting workout (attempt ${attempt + 1})`);
        let content = '';
        try {
          const completion = await this.openai.createChatCompletion({
            model: 'gpt-4',
            messages,
          });
          this.logger.info(`received format response`, { ...completion.data?.usage, finishReason: completion.data?.choices[0]?.finish_reason });
          response.completionId = completion.data?.id;
          content = completion.data?.choices[0].message?.content ?? '';
        } catch (error: any) {
          this.logger.error(`Format attempt ${attempt + 1} failed`, { error: { message: error.message, status: error.status, data: error.response?.data } });
          validJson = false;
          continue;
        }

        // validate the response and provide default values if needed
        let workout;
        try {
          workout = this.validateAndCorrect(content);
          const isValid = this.schemaValidator(workout);
          if (!isValid) {
            throw new Error(`Invalid workout response: ${JSON.stringify(this.schemaValidator.errors)}`);
          }
          response.workout = workout;
          //////////////////////////
          validJson = true;
          break; // success
        } catch (error: any) {
          this.logger.error(`Failed to validate workout ${attempt + 1} response: ${error.message}`);
          this.logger.debug(`Workout response: ${JSON.stringify(workout)}`);
          //////////////////////////
          validJson = false;
          continue; // retry
        }
      }
      if (!validJson) {
        this.logger.error(`Failed to validate workout response after ${maxRetries} attempts`);
        response.workout = this.defaultValues();
        response.empty = true;
      }
      return response;
    } catch (error) {
      return { ...response, error: error as Error };
    }
  }

  public async addExercise({ section, formattedWorkout }: AddExerciseRequest) {
    let stringifiedWorkout = JSON.stringify(formattedWorkout, null, 2);
    const messages: ChatCompletionRequestMessage[] = [
      { role: 'system', content: `As an AI Fitness Mentor, you create dynamic, daily workouts tailored to user preferences. Your role is to evaluate a given workout and suggest a new exercise that will complement the existing exercises, paying close attention to the equipment, or lack thereof, being used. For example, if the given workout only consists of body weight exercises, do not suggest an exercise that requires dumbbells.` },
      { role: 'user', content: `Add another exercise to the ${section} section of the following workout: ${stringifiedWorkout}\n\nOnly return the JSON for the new exercise and no other text. Ensure it matches the same JSON structure as the given workout.` }
    ];
    try {
      const completion = await this.createChatCompletion({ messages, model: 'gpt-4' });
      const completionId = completion.data?.id;
      this.logger.debug(`received add exercise response`, { ...completion.data?.usage, finishReason: completion.data?.choices[0]?.finish_reason });
      console.log(completion.data?.choices[0].message?.content ?? 'NOT_SET')

      const exercise = JSON.parse(completion.data?.choices[0].message?.content ?? 'NOT_SET');
      if (exercise === 'NOT_SET') {
        throw new Error('Failed to generate new exercise');
      }

      return { exercise, completionId };
    } catch (error) {
      return { error: error as Error };
    }
  }

  public async remixExercise({ workout, exercise, feedback, section }: RemixExerciseRequest) {
    const systemPrompt = new SystemPrompt(GenerateWorkoutEvent.EXERCISE_REMIXED);
    let stringifiedWorkout = JSON.stringify(workout, null, 2);
    let stringifiedExercise = JSON.stringify(exercise, null, 2);

    const messages: ChatCompletionRequestMessage[] = [
      systemPrompt.message,
      { role: 'user', content: `Consider the following workout: ${stringifiedWorkout}\n\nCreate an alernative to the following exercise based on the user's feedback:\nEXERCISE\n${stringifiedExercise}\n\nFEEDBACK\n${feedback}\n\nOnly return the JSON for the new exercise and no other text. Ensure it matches the same JSON structure as the exercise you replaced.` }
    ];
    try {
      const completion = await this.createChatCompletion({ messages, model: 'gpt-4' });
      const completionId = completion.data?.id;
      this.logger.debug(`received add exercise response`, { ...completion.data?.usage, finishReason: completion.data?.choices[0]?.finish_reason });
      console.log(completion.data?.choices[0].message?.content ?? 'NOT_SET')

      const exercise = JSON.parse(completion.data?.choices[0].message?.content ?? 'NOT_SET');
      if (exercise === 'NOT_SET') {
        throw new Error('Failed to remix exercise');
      }

      return { exercise, completionId };
    } catch (error) {
      return { error: error as Error };
    }
  }

  private async createChatCompletion({ model, messages }: CreateChatCompletionRequest) {
    return await this.openai.createChatCompletion({ model, messages });
  }

  private validateAndCorrect(dataStr: string): any {
    let data;
    try {
      data = JSON.parse(dataStr);
    } catch (error: any) {
      error.message = `INVALID_JSON: ${error.message}`
      throw error
    }
    // Make sure muscle_groups is an array
    if (!Array.isArray(data.muscle_groups)) {
      data.muscle_groups = [];
    }

    // Make sure work is an object
    if (typeof data.work !== 'object') {
      data.work = {
        warmup: { exercises: [] },
        main: { exercises: [] },
        cardio: { exercises: [] },
        cooldown: { exercises: [] },
      };
    } else {
      // Validate and correct nested fields in work
      data.work = this.validateAndCorrectWork(data.work);
    }

    return data;
  }

  private validateAndCorrectWork(work: any): any {
    const fields = ['warmup', 'main', 'cardio', 'cooldown'];

    fields.forEach((field) => {
      if (!Array.isArray(work[field]?.exercises)) {
        work[field] = { exercises: [] };
      } else if (field === 'main') {
        // Validate and correct sets for main workouts
        work[field].exercises = work[field].exercises.map(this.validateAndCorrectSets);
      }
    });

    return work;
  }

  private validateAndCorrectSets(exercise: any): any {
    // Make sure sets is an array
    if (!Array.isArray(exercise.sets)) {
      exercise.sets = [{ reps: 0 }]; // default value
    } else {
      exercise.sets = exercise.sets.map((set: any) => {
        // Make sure each set is an object with a reps attribute
        if (typeof set !== 'object' || !('reps' in set)) {
          return { reps: 0 }; // default value
        }
        return set;
      });
    }

    return exercise;
  }

  // Function to provide default values
  private defaultValues(): any {
    return {
      muscle_groups: [],
      work: {
        warmup: { exercises: [] },
        main: { exercises: [] },
        cardio: { exercises: [] },
        cooldown: { exercises: [] },
      },
    };
  }
}
