import { Send } from "lucide-react"
import { useEffect, useState } from "react"
import { PipelineConfigModal } from "./PipelineConfigModal"
import type { PipelineConfig } from "@/types/pipelineConfig"
import { PRESET_BALANCED } from "@/types/pipelineConfig"
import { usePipelinePresets } from "@/hooks/usePipelinePresets"

interface Props {
  onMessageSent: ((message: string, config: PipelineConfig) => Promise<void>) | null;
}

export function ChatInput(props: Props): React.JSX.Element {
  const { currentPreset } = usePipelinePresets()
  const [currentConfig, setCurrentConfig] = useState<PipelineConfig>(PRESET_BALANCED.config)

  // Update config when global preset changes
  useEffect(() => {
    if (currentPreset) {
      setCurrentConfig(currentPreset.config)
    }
  }, [currentPreset])

  function handleKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  function handleSend() {
    const input = document.getElementById("chat-input") as HTMLTextAreaElement
    const message = input.value.trim()
    if (message) {
      props.onMessageSent && props.onMessageSent(message, currentConfig)
      input.value = ""
    }
  }

  const handleConfigChange = (config: PipelineConfig) => {
    setCurrentConfig(config)
    console.log("Config changed:", config)
  }

  return (
    <div className="border rounded-xl flex items-center gap-2 px-3 py-2 bg-background">
      <textarea id="chat-input"
        placeholder="Type your message..."
        className="flex-1 resize-none bg-transparent outline-none text-sm"
        rows={1}
        onKeyDown={handleKeyDown}
      />

      <PipelineConfigModal onConfigChange={handleConfigChange} />

      <button className="ml-2 p-2 rounded-lg hover:bg-muted transition" onClick={handleSend}>
        <Send className="w-4 h-4" />
      </button>
    </div>
  )
}
