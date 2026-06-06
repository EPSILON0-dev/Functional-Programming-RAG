import { Send } from "lucide-react"
import { useContext, useEffect } from "react"
import { PipelineConfigModal } from "./PipelineConfigModal"
import type { PipelineConfig } from "@/types/pipelineConfig"
import { PRESET_BALANCED } from "@/types/pipelineConfig"
import { usePipelinePresets } from "@/hooks/usePipelinePresets"
import { AppContext } from "@/AppContext"

interface Props {
  onMessageSent: ((message: string, config: PipelineConfig) => Promise<void>) | null;
}

export function ChatInput(props: Props): React.JSX.Element {
  const ctx = useContext(AppContext);
  const { currentPreset } = usePipelinePresets()

  // Update config when global preset changes
  useEffect(() => {
    if (currentPreset) {
      ctx?.dispatch({ type: "SET_PIPELINE_CONFIG", payload: currentPreset.config });
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
      props.onMessageSent && props.onMessageSent(message, ctx?.state.pipelineConfig ?? PRESET_BALANCED.config)
      input.value = ""
    }
  }

  const handleConfigChange = (config: PipelineConfig) => {
    ctx?.dispatch({ type: "SET_PIPELINE_CONFIG", payload: config });
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
