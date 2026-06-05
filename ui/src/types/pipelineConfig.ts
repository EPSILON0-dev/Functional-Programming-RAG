export interface PipelineConfig {
  // Stage 1: Topic Extraction
  topic_extraction_model: string;
  topic_extraction_temperature: number;
  topic_extraction_top_p: number;
  topic_extraction_kb_needed_threshold: number;

  // Stage 2: Uninformed Response
  uninformed_response_model: string;
  uninformed_response_temperature: number;
  uninformed_response_top_p: number;

  // Stage 3: Embedding Retrieval
  per_search_limit: number;

  // Stage 4: Rerank Stage
  rerank_model: string;
  rerank_double_pass_enabled: boolean;
  rerank_top_k: number;
  rerank_temperature: number;
  rerank_top_p: number;

  // Stage 5: Generation
  parallel_generations: number;
  generation_model: string;
  generation_temperature: number;
  generation_top_p: number;
  generation_reasoning_enabled: boolean;
  generation_reasoning_effort: "low" | "medium" | "high";

  // Stage 6: Response Rerank
  response_rerank_model: string;
  response_rerank_temperature: number;
  response_rerank_top_p: number;
}

export interface PresetDefinition {
  name: string;
  description: string;
  isCustom: boolean;
  config: PipelineConfig;
}

// Default presets
export const PRESET_STUPID: PresetDefinition = {
  name: "Stupid",
  description: "Creative, fast, uses less computation",
  isCustom: false,
  config: {
    topic_extraction_model: "openai/gpt-5.4-nano",
    topic_extraction_temperature: 0.8,
    topic_extraction_top_p: 0.95,
    topic_extraction_kb_needed_threshold: 0.3,
    uninformed_response_model: "openai/gpt-5.4-mini",
    uninformed_response_temperature: 0.9,
    uninformed_response_top_p: 0.95,
    per_search_limit: 5,
    rerank_model: "openai/gpt-5.4-nano",
    rerank_double_pass_enabled: false,
    rerank_top_k: 5,
    rerank_temperature: 0.3,
    rerank_top_p: 0.9,
    parallel_generations: 1,
    generation_model: "openai/gpt-5.4-mini",
    generation_temperature: 0.9,
    generation_top_p: 0.95,
    generation_reasoning_enabled: false,
    generation_reasoning_effort: "low",
    response_rerank_model: "openai/gpt-5.4-nano",
    response_rerank_temperature: 0.5,
    response_rerank_top_p: 1.0,
  },
};

export const PRESET_BALANCED: PresetDefinition = {
  name: "Balanced",
  description: "Moderate creativity and accuracy",
  isCustom: false,
  config: {
    topic_extraction_model: "gpt-4-turbo",
    topic_extraction_temperature: 0.5,
    topic_extraction_top_p: 0.9,
    topic_extraction_kb_needed_threshold: 0.5,
    uninformed_response_model: "gpt-4-turbo",
    uninformed_response_temperature: 0.7,
    uninformed_response_top_p: 0.95,
    per_search_limit: 10,
    rerank_model: "gpt-4-turbo",
    rerank_double_pass_enabled: true,
    rerank_top_k: 10,
    rerank_temperature: 0.3,
    rerank_top_p: 0.9,
    parallel_generations: 2,
    generation_model: "gpt-4-turbo",
    generation_temperature: 0.7,
    generation_top_p: 0.95,
    generation_reasoning_enabled: true,
    generation_reasoning_effort: "low",
    response_rerank_model: "gpt-4-turbo",
    response_rerank_temperature: 0.0,
    response_rerank_top_p: 1.0,
  },
};

export const PRESET_SMART: PresetDefinition = {
  name: "Smart",
  description: "Precise, thorough, uses more computation",
  isCustom: false,
  config: {
    topic_extraction_model: "gpt-4",
    topic_extraction_temperature: 0.1,
    topic_extraction_top_p: 0.9,
    topic_extraction_kb_needed_threshold: 0.7,
    uninformed_response_model: "gpt-4",
    uninformed_response_temperature: 0.3,
    uninformed_response_top_p: 0.9,
    per_search_limit: 20,
    rerank_model: "gpt-4",
    rerank_double_pass_enabled: true,
    rerank_top_k: 15,
    rerank_temperature: 0.1,
    rerank_top_p: 0.9,
    parallel_generations: 3,
    generation_model: "gpt-4",
    generation_temperature: 0.3,
    generation_top_p: 0.9,
    generation_reasoning_enabled: true,
    generation_reasoning_effort: "high",
    response_rerank_model: "gpt-4",
    response_rerank_temperature: 0.0,
    response_rerank_top_p: 1.0,
  },
};

export const DEFAULT_PRESETS = [PRESET_STUPID, PRESET_BALANCED, PRESET_SMART];
