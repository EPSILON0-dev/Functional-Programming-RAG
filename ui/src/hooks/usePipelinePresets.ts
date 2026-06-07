import { useState, useEffect } from "react";
import type { PipelineConfig, PresetDefinition } from "@/types/pipelineConfig";
import { DEFAULT_PRESETS, PRESET_BALANCED } from "@/types/pipelineConfig";

const STORAGE_KEY = "pipelineConfigPresets";
const LAST_PRESET_KEY = "lastUsedPreset";

/**
 * Hook for managing pipeline configuration presets in localStorage
 */
export function usePipelinePresets() {
  const [presets, setPresets] = useState<PresetDefinition[]>(DEFAULT_PRESETS);
  const [currentPreset, setCurrentPresetState] = useState<PresetDefinition | null>(null);

  // Load custom presets and last used preset from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    let allPresets = DEFAULT_PRESETS;
    if (stored) {
      try {
        const customPresets = JSON.parse(stored) as PresetDefinition[];
        allPresets = [...DEFAULT_PRESETS, ...customPresets];
        setPresets(allPresets);
      } catch (e) {
        console.error("Failed to load presets from localStorage:", e);
      }
    }

    const lastPresetName = localStorage.getItem(LAST_PRESET_KEY);
    if (lastPresetName) {
      const lastPreset = allPresets.find((p) => p.name === lastPresetName);
      if (lastPreset) {
        setCurrentPresetState(lastPreset);
      }
    } else {
      setCurrentPresetState(PRESET_BALANCED);
    }
  }, []);

  const setCurrentPreset = (preset: PresetDefinition | null) => {
    setCurrentPresetState(preset);
    if (preset) {
      localStorage.setItem(LAST_PRESET_KEY, preset.name);
    }
  };

  const saveCustomPreset = (name: string, config: PipelineConfig) => {
    const newPreset: PresetDefinition = {
      name,
      description: `Custom preset: ${name}`,
      isCustom: true,
      config,
    };

    const customPresets = presets.filter((p) => p.isCustom);
    const updated = [...customPresets, newPreset];

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
      setPresets([...DEFAULT_PRESETS, ...updated]);
      return newPreset;
    } catch (e) {
      console.error("Failed to save preset:", e);
      throw e;
    }
  };

  const updateCustomPreset = (name: string, config: PipelineConfig) => {
    const customPresets = presets.filter((p) => p.isCustom);
    const updated = customPresets.map((p) =>
      p.name === name ? { ...p, config } : p
    );

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
      setPresets([...DEFAULT_PRESETS, ...updated]);
    } catch (e) {
      console.error("Failed to update preset:", e);
      throw e;
    }
  };

  const deleteCustomPreset = (name: string) => {
    const customPresets = presets.filter((p) => p.isCustom && p.name !== name);

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(customPresets));
      setPresets([...DEFAULT_PRESETS, ...customPresets]);
    } catch (e) {
      console.error("Failed to delete preset:", e);
      throw e;
    }
  };

  return {
    presets,
    currentPreset,
    setCurrentPreset,
    saveCustomPreset,
    updateCustomPreset,
    deleteCustomPreset,
  };
}
