import { useState } from "react"
import { Settings2, Plus, Trash2, Check } from "lucide-react"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { Slider } from "@/components/ui/slider"
import { Checkbox } from "@/components/ui/checkbox"
import { toast } from "sonner"
import { usePipelinePresets } from "@/hooks/usePipelinePresets"
import type { PipelineConfig } from "@/types/pipelineConfig"
import { PRESET_BALANCED } from "@/types/pipelineConfig"
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select"

interface Props {
  onConfigChange?: (config: PipelineConfig) => void
}

const MODEL_OPTIONS = [
  // OpenAI
  { value: "openai/gpt-5.4-nano", label: "GPT-5.4 Nano" },
  { value: "openai/gpt-5.4-mini", label: "GPT-5.4 Mini" },
  { value: "openai/gpt-5.4", label: "GPT-5.4" },
  // Google
  { value: "google/gemini-2.5-flash", label: "Gemini 2.5 Flash" },
  // Anthropic
  { value: "anthropic/claude-sonnet-4.6", label: "Claude Sonnet 4.6" },
  { value: "anthropic/claude-haiku-4.5", label: "Claude Haiku 4.5" },
  // Kimi (Moonshot AI)
  { value: "moonshotai/kimi-k2.5", label: "Kimi K2.5" },
  // DeepSeek
  { value: "deepseek/deepseek-v4-flash", label: "DeepSeek V4 Flash" },
  { value: "deepseek/deepseek-v4-pro", label: "DeepSeek V4 Pro" },
]

type Tab = "presets" | "models" | "retrieval" | "generation" | "reranking"

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide mb-3">
      {children}
    </p>
  )
}

function SliderField({
  label,
  hint,
  value,
  min,
  max,
  step,
  precision,
  onChange,
  disabled = false,
}: {
  label: string
  hint?: string
  value: number
  min: number
  max: number
  step: number
  precision: number
  onChange: (v: number) => void
  disabled?: boolean
}) {
  return (
    <div className={`space-y-2 ${disabled ? "opacity-50" : ""}`}>
      <div className="flex items-center justify-between gap-4">
        <div className="space-y-0.5 flex-1">
          <Label className={`text-sm font-medium ${disabled ? "text-muted-foreground" : ""}`}>{label}</Label>
          {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
        </div>
        <span className="text-sm font-medium tabular-nums shrink-0 w-12 text-right">
          {value.toFixed(precision)}
        </span>
      </div>
      <Slider
        value={value}
        onValueChange={(v) => !disabled && onChange(typeof v === "number" ? v : v[0])}
        min={min}
        max={max}
        step={step}
        className="w-full"
        disabled={disabled}
      />
    </div>
  )
}

function ToggleField({
  label,
  description,
  checked,
  onChange,
  disabled = false,
}: {
  label: string
  description?: string
  checked: boolean
  onChange: (v: boolean) => void
  disabled?: boolean
}) {
  return (
    <div className={`flex items-start justify-between gap-4 ${disabled ? "opacity-50" : ""}`}>
      <div className="space-y-0.5">
        <Label className={`text-sm font-medium ${disabled ? "text-muted-foreground" : ""}`}>{label}</Label>
        {description && <p className="text-xs text-muted-foreground">{description}</p>}
      </div>
      <Checkbox
        checked={checked}
        onCheckedChange={(v) => !disabled && onChange(v as boolean)}
        className="mt-0.5"
        disabled={disabled}
      />
    </div>
  )
}

function ModelSelectField({
  label,
  value,
  options,
  onChange,
  disabled = false,
}: {
  label: string
  value: string
  options: { value: string; label: string }[]
  onChange: (v: string) => void
  disabled?: boolean
}) {
  return (
    <div className={`flex items-center justify-between gap-4 ${disabled ? "opacity-50" : ""}`}>
      <Label className={`text-sm font-medium shrink-0 ${disabled ? "text-muted-foreground" : ""}`}>{label}</Label>
      <div className="flex items-center gap-2">
        <Select value={value} onValueChange={(v, _) => { !disabled && onChange(v || "") }} disabled={disabled}>
          <SelectTrigger className="w-52">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {options.map((o) => (
              <SelectItem key={o.value} value={o.value}>
                {o.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
    </div>
  )
}

export function PipelineConfigModal({ onConfigChange }: Props): React.JSX.Element {
  const { presets, currentPreset, setCurrentPreset, saveCustomPreset, updateCustomPreset, deleteCustomPreset } =
    usePipelinePresets()

  const [tab, setTab] = useState<Tab>("presets")
  const [showExpert, setShowExpert] = useState(false)
  const defaultConfig = PRESET_BALANCED.config
  const [config, setConfig] = useState<PipelineConfig>(
    { ...defaultConfig, ...(currentPreset?.config ?? presets[1]?.config ?? presets[0].config) }
  )
  const [newPresetName, setNewPresetName] = useState("")
  const [savingPreset, setSavingPreset] = useState(false)

  // Check if current preset is a built-in (read-only) or custom (editable)
  const isReadOnly = currentPreset ? !currentPreset.isCustom : false

  const update = <K extends keyof PipelineConfig>(key: K, value: PipelineConfig[K]) => {
    const next = { ...config, [key]: value }
    setConfig(next)
    // Auto-save when editing a custom preset
    if (currentPreset?.isCustom) {
      updateCustomPreset(currentPreset.name, next)
    }
    onConfigChange?.(next)
  }

  const applyPreset = (name: string) => {
    const preset = presets.find((p) => p.name === name)
    if (!preset) return
    const merged = { ...defaultConfig, ...preset.config }
    setCurrentPreset(preset)
    setConfig(merged)
    onConfigChange?.(merged)
  }

  const handleSave = () => {
    if (!newPresetName.trim()) { toast.error("Name cannot be empty"); return }
    try {
      saveCustomPreset(newPresetName.trim(), config)
      toast.success(`Preset "${newPresetName.trim()}" saved`)
      setNewPresetName("")
      setSavingPreset(false)
    } catch {
      toast.error("Failed to save preset")
    }
  }

  const TABS: { id: Tab; label: string }[] = [
    { id: "presets", label: "Presets" },
    { id: "models", label: "Models" },
    { id: "retrieval", label: "Retrieval" },
    { id: "generation", label: "Generation" },
    { id: "reranking", label: "Reranking" },
  ]

  return (
    <Dialog>
      <DialogTrigger
        render={
          <Button variant="ghost" size="icon-sm" title="Pipeline configuration">
            <Settings2 className="w-4 h-4" />
          </Button>
        }
      />

      <DialogContent
        className="max-w-2xl! w-full p-0 overflow-hidden"
        showCloseButton={false}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 pt-5 pb-3">
          <div>
            <h2 className="text-base font-semibold">Pipeline Configuration</h2>
            <p className="text-xs text-muted-foreground">
              Active:{" "}
              <span className="font-medium text-foreground">
                {currentPreset?.name ?? "Custom"}
              </span>
            </p>
          </div>
          <DialogClose
            render={
              <Button variant="ghost" size="icon-sm">
                ✕
              </Button>
            }
          />
        </div>

        {/* Tab bar */}
        <div className="flex gap-1 px-5 border-b pb-0">
          {TABS.map((t) => {
            const disabled = isReadOnly && t.id !== "presets"
            return (
              <button
                key={t.id}
                onClick={() => !disabled && setTab(t.id)}
                disabled={disabled}
                className={`px-3 py-2 text-sm font-medium border-b-2 transition-colors -mb-px ${disabled
                  ? "border-transparent text-muted-foreground/30 cursor-not-allowed"
                  : tab === t.id
                    ? "border-primary text-primary"
                    : "border-transparent text-muted-foreground hover:text-foreground"
                  }`}
              >
                {t.label}
              </button>
            )
          })}
        </div>

        {/* Tab content */}
        <div className="px-5 py-4 overflow-y-auto max-h-[60vh] space-y-4">

          {/* Presets */}
          {tab === "presets" && (
            <>
              <div className="grid grid-cols-3 gap-2">
                {presets.filter((p) => !p.isCustom).map((p) => (
                  <button
                    key={p.name}
                    onClick={() => applyPreset(p.name)}
                    className={`relative flex flex-col items-start rounded-lg border-2 p-3 text-left transition-all hover:border-primary/50 ${currentPreset?.name === p.name
                      ? "border-primary bg-primary/5"
                      : "border-border"
                      }`}
                  >
                    {currentPreset?.name === p.name && (
                      <Check className="absolute top-2 right-2 w-3.5 h-3.5 text-primary" />
                    )}
                    <span className="font-medium text-sm">{p.name}</span>
                    <span className="text-xs text-muted-foreground mt-0.5">{p.description}</span>
                  </button>
                ))}
              </div>

              {/* Custom Presets Section */}
              {presets.filter((p) => p.isCustom).length > 0 && (
                <div className="space-y-2">
                  <SectionLabel>Custom</SectionLabel>
                  <div className="space-y-1">
                    {presets.filter((p) => p.isCustom).map((p) => (
                      <div
                        key={p.name}
                        className={`flex items-center justify-between rounded-lg border px-3 py-2.5 cursor-pointer transition-colors hover:bg-muted/50 ${currentPreset?.name === p.name ? "border-primary bg-primary/5" : "border-border"
                          }`}
                        onClick={() => applyPreset(p.name)}
                      >
                        <div className="flex items-center gap-2">
                          {currentPreset?.name === p.name && (
                            <Check className="w-3.5 h-3.5 text-primary shrink-0" />
                          )}
                          <span className="text-sm font-medium">{p.name}</span>
                        </div>
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            deleteCustomPreset(p.name)
                            toast.success(`Preset "${p.name}" deleted`)
                          }}
                          className="p-1 rounded hover:bg-red-100 hover:text-red-600 text-muted-foreground transition-colors"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <div className="pt-2 border-t">
                {savingPreset ? (
                  <div className="flex gap-2">
                    <Input
                      placeholder="Preset name"
                      value={newPresetName}
                      autoFocus
                      onChange={(e) => setNewPresetName(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") handleSave()
                        if (e.key === "Escape") { setSavingPreset(false); setNewPresetName("") }
                      }}
                    />
                    <Button size="sm" onClick={handleSave}>Save</Button>
                    <Button size="sm" variant="ghost" onClick={() => { setSavingPreset(false); setNewPresetName("") }}>
                      Cancel
                    </Button>
                  </div>
                ) : (
                  <Button
                    variant="outline"
                    size="sm"
                    className="w-full gap-1.5"
                    onClick={() => setSavingPreset(true)}
                  >
                    <Plus className="w-3.5 h-3.5" />
                    New
                  </Button>
                )}
              </div>
            </>
          )}

          {/* Models */}
          {tab === "models" && (
            <div className="space-y-5">
              <div className="space-y-3">
                <SectionLabel>Generation</SectionLabel>
                <ModelSelectField
                  label="Main generation"
                  value={config.generation_model}
                  options={MODEL_OPTIONS}
                  onChange={(v) => update("generation_model", v)}
                  disabled={isReadOnly}
                />
                <ModelSelectField
                  label="Uninformed response"
                  value={config.uninformed_response_model}
                  options={MODEL_OPTIONS}
                  onChange={(v) => update("uninformed_response_model", v)}
                  disabled={isReadOnly}
                />
              </div>
              <div className="space-y-3">
                <SectionLabel>Utility</SectionLabel>
                <ModelSelectField
                  label="Topic extraction"
                  value={config.topic_extraction_model}
                  options={MODEL_OPTIONS}
                  onChange={(v) => update("topic_extraction_model", v)}
                  disabled={isReadOnly}
                />
                <ModelSelectField
                  label="Doc reranking"
                  value={config.rerank_model}
                  options={MODEL_OPTIONS}
                  onChange={(v) => update("rerank_model", v)}
                  disabled={isReadOnly}
                />
                <ModelSelectField
                  label="Response reranking"
                  value={config.response_rerank_model}
                  options={MODEL_OPTIONS}
                  onChange={(v) => update("response_rerank_model", v)}
                  disabled={isReadOnly}
                />
              </div>
            </div>
          )}

          {/* Retrieval */}
          {tab === "retrieval" && (
            <div className="space-y-5">
              <div className="space-y-4">
                <SectionLabel>Knowledge Base</SectionLabel>
                <SliderField
                  label="KB Lookup Threshold"
                  hint="Minimum confidence score to trigger a knowledge base lookup. Lower = always look up."
                  value={config.topic_extraction_kb_needed_threshold}
                  min={0} max={1} step={0.05} precision={2}
                  onChange={(v) => update("topic_extraction_kb_needed_threshold", v)}
                  disabled={isReadOnly}
                />
              </div>
              <div className="space-y-4">
                <SectionLabel>Search</SectionLabel>
                <SliderField
                  label="Per-Search Limit"
                  hint="Documents retrieved per embedding query before deduplication."
                  value={config.per_search_limit}
                  min={1} max={50} step={1} precision={0}
                  onChange={(v) => update("per_search_limit", v)}
                  disabled={isReadOnly}
                />
              </div>
              {showExpert && (
                <div className="space-y-4 border-t pt-4">
                  <SectionLabel>Expert — Topic Extraction Sampling</SectionLabel>
                  <SliderField
                    label="Temperature"
                    value={config.topic_extraction_temperature}
                    min={0} max={2} step={0.05} precision={2}
                    onChange={(v) => update("topic_extraction_temperature", v)}
                    disabled={isReadOnly}
                  />
                  <SliderField
                    label="Top-P"
                    value={config.topic_extraction_top_p}
                    min={0} max={1} step={0.05} precision={2}
                    onChange={(v) => update("topic_extraction_top_p", v)}
                    disabled={isReadOnly}
                  />
                </div>
              )}
            </div>
          )}

          {/* Generation */}
          {tab === "generation" && (
            <div className="space-y-5">
              <div className="space-y-4">
                <SectionLabel>Candidates</SectionLabel>
                <SliderField
                  label="Parallel Generations"
                  hint="Number of response candidates generated simultaneously. Best one is picked."
                  value={config.parallel_generations}
                  min={1} max={5} step={1} precision={0}
                  onChange={(v) => update("parallel_generations", v)}
                  disabled={isReadOnly}
                />
              </div>
              {showExpert && (
                <>
                  <div className="space-y-4 border-t pt-4">
                    <SectionLabel>Expert — Sampling</SectionLabel>
                    <SliderField
                      label="Generation Temperature"
                      value={config.generation_temperature}
                      min={0} max={2} step={0.05} precision={2}
                      onChange={(v) => update("generation_temperature", v)}
                      disabled={isReadOnly}
                    />
                    <SliderField
                      label="Generation Top-P"
                      value={config.generation_top_p}
                      min={0} max={1} step={0.05} precision={2}
                      onChange={(v) => update("generation_top_p", v)}
                      disabled={isReadOnly}
                    />
                    <SliderField
                      label="Uninformed Response Temperature"
                      value={config.uninformed_response_temperature}
                      min={0} max={2} step={0.05} precision={2}
                      onChange={(v) => update("uninformed_response_temperature", v)}
                      disabled={isReadOnly}
                    />
                    <SliderField
                      label="Uninformed Response Top-P"
                      value={config.uninformed_response_top_p}
                      min={0} max={1} step={0.05} precision={2}
                      onChange={(v) => update("uninformed_response_top_p", v)}
                      disabled={isReadOnly}
                    />
                  </div>
                  <div className="space-y-4 border-t pt-4">
                    <SectionLabel>Expert — Reasoning</SectionLabel>
                    <ToggleField
                      label="Enable Reasoning"
                      description="Extended chain-of-thought before generating the response."
                      checked={config.generation_reasoning_enabled}
                      onChange={(v) => update("generation_reasoning_enabled", v)}
                      disabled={isReadOnly}
                    />
                    {config.generation_reasoning_enabled && (
                      <div className={`flex items-center justify-between gap-4 ${isReadOnly ? "opacity-50" : ""}`}>
                        <Label className={`text-sm font-medium ${isReadOnly ? "text-muted-foreground" : ""}`}>Reasoning Effort</Label>
                        <Select
                          value={config.generation_reasoning_effort}
                          onValueChange={(v) =>
                            !isReadOnly && update("generation_reasoning_effort", v as "low" | "medium" | "high")
                          }
                          disabled={isReadOnly}
                        >
                          <SelectTrigger className="w-32">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="low">Low</SelectItem>
                            <SelectItem value="medium">Medium</SelectItem>
                            <SelectItem value="high">High</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    )}
                  </div>
                </>
              )}
            </div>
          )}

          {/* Reranking */}
          {tab === "reranking" && (
            <div className="space-y-5">
              <div className="space-y-4">
                <SectionLabel>Document Reranking</SectionLabel>
                <ToggleField
                  label="Double-Pass Reranking"
                  description="Score documents forward and reverse, then average scores. Reduces positional bias."
                  checked={config.rerank_double_pass_enabled}
                  onChange={(v) => update("rerank_double_pass_enabled", v)}
                  disabled={isReadOnly}
                />
                <SliderField
                  label="Top-K Documents"
                  hint="How many reranked documents are passed to generation."
                  value={config.rerank_top_k}
                  min={1} max={30} step={1} precision={0}
                  onChange={(v) => update("rerank_top_k", v)}
                  disabled={isReadOnly}
                />
              </div>
              {showExpert && (
                <div className="space-y-4 border-t pt-4">
                  <SectionLabel>Expert — Sampling</SectionLabel>
                  <SliderField
                    label="Document Reranking Temperature"
                    value={config.rerank_temperature}
                    min={0} max={2} step={0.05} precision={2}
                    onChange={(v) => update("rerank_temperature", v)}
                  />
                  <SliderField
                    label="Document Reranking Top-P"
                    value={config.rerank_top_p}
                    min={0} max={1} step={0.05} precision={2}
                    onChange={(v) => update("rerank_top_p", v)}
                  />
                  <SliderField
                    label="Response Reranking Temperature"
                    value={config.response_rerank_temperature}
                    min={0} max={2} step={0.05} precision={2}
                    onChange={(v) => update("response_rerank_temperature", v)}
                  />
                  <SliderField
                    label="Response Reranking Top-P"
                    value={config.response_rerank_top_p}
                    min={0} max={1} step={0.05} precision={2}
                    onChange={(v) => update("response_rerank_top_p", v)}
                    disabled={isReadOnly}
                  />
                </div>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-5 py-3 border-t bg-muted/30">
          <label className={`flex items-center gap-2 select-none ${isReadOnly ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`}>
            <Checkbox
              checked={showExpert}
              onCheckedChange={(v) => !isReadOnly && setShowExpert(v as boolean)}
              disabled={isReadOnly}
            />
            <span className="text-xs text-muted-foreground">Expert mode</span>
          </label>
          <DialogClose
            render={<Button size="sm">Done</Button>}
          />
        </div>
      </DialogContent>
    </Dialog>
  )
}
