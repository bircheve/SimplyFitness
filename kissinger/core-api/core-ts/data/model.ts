export enum CompletionStatus {
  INCOMPLETE = 'incomplete',
  SKIPPED = 'skipped',
  IN_PROGRESS = 'in_progress',
  COMPLETE = 'complete',
}

export enum GPTStatus {
  PENDING = 'pending',
  COMPLETE = 'complete',
  ERROR = 'error',
}

export enum ChatRole {
  ASSISTANT = 'assistant',
  SYSTEM = 'system',
  USER = 'user',
}

export enum StoryEntity {
  STORY = 'story',
  WORKOUT = 'workout',
  FEEDBACK = 'feedback',
  REMIX = 'remix',
}

type DateTimeString = string;

// Generic type for a DynamoDB record
type Record = {
  PK: string;
  SK: string;
  GSIPK?: string;
  GSISK?: string;
  userId: string;
  entity: string;
  createdAt: DateTimeString;
  updatedAt?: DateTimeString;
};

// STORY
type StoryRecord = Record & {
  prompt: string;
};
export type Story = Omit<StoryRecord, 'PK' | 'SK' | 'GSI1PK' | 'GSI1SK'>;

// WORKOUT
type WorkoutRecord = Record & {
  workout: any;
  status: CompletionStatus;
  gptStatus: GPTStatus;
  scheduledFor: DateTimeString;
  chatRole: ChatRole;
};
export type Workout = Omit<WorkoutRecord, 'PK' | 'SK' | 'GSI1PK' | 'GSI1SK'>;
export type CompletedWorkout = Omit<WorkoutRecord, 'updatedAt'> & {
  updatedAt: DateTimeString; // override to not be optional
  completedAt?: DateTimeString;
}

export const exerciseSections = [ 'warmup', 'main', 'cardio', 'cooldown' ] as const;
export type ExerciseSection = typeof exerciseSections[number];

export type Exercise = {
  id: string;
  name: string;
  instructions: string;
  equipment: string;
  muscle_groups: string[];
  sets: { reps: number }[];
}
export type TimeBasedExercise = Exercise & { duration: number };

// FEEDBACK
type FeedbackRecord = Record & {
  value: string;
  workoutId: string;
  workouSummary: any;
  chatRole: ChatRole;
};
export type Feedback = Omit<FeedbackRecord, 'PK' | 'SK' | 'GSI1PK' | 'GSI1SK'>;
