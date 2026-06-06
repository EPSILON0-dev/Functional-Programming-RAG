import { Send } from "lucide-react"
import { useContext, useEffect, useRef, useState } from "react"
import { PipelineConfigModal } from "./PipelineConfigModal"
import type { PipelineConfig } from "@/types/pipelineConfig"
import { PRESET_BALANCED } from "@/types/pipelineConfig"
import { usePipelinePresets } from "@/hooks/usePipelinePresets"
import { AppContext } from "@/AppContext"

interface Props {
  onMessageSent: ((message: string, config: PipelineConfig) => Promise<void>) | null;
}

const MAX_ROWS = 5;

export function ChatInput(props: Props): React.JSX.Element {
  const ctx = useContext(AppContext);
  const { currentPreset } = usePipelinePresets()
  const textareaRef = useRef<HTMLTextAreaElement>(null)
  const [rows, setRows] = useState(1)

  useEffect(() => {
    if (currentPreset) {
      ctx?.dispatch({ type: "SET_PIPELINE_CONFIG", payload: currentPreset.config });
    }
  }, [currentPreset])

  function adjustRows() {
    const textarea = textareaRef.current
    if (!textarea) return

    textarea.rows = 1
    const lineHeight = 20
    const padding = 8
    const contentHeight = textarea.scrollHeight - padding
    const newRows = Math.min(Math.max(1, Math.ceil(contentHeight / lineHeight)), MAX_ROWS)
    
    setRows(newRows)
    textarea.rows = newRows
  }

  function handleInput() {
    adjustRows()
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  function handleSend() {
    const textarea = textareaRef.current
    if (!textarea) return
    const message = textarea.value.trim()
    if (message) {
      props.onMessageSent && props.onMessageSent(message, ctx?.state.pipelineConfig ?? PRESET_BALANCED.config)
      textarea.value = ""
      setRows(1)
      textarea.rows = 1
    }
  }

  const handleConfigChange = (config: PipelineConfig) => {
    ctx?.dispatch({ type: "SET_PIPELINE_CONFIG", payload: config });
  }

  return (
    <div className="border rounded-xl flex items-center gap-2 px-3 py-2 bg-background">
      <textarea
        ref={textareaRef}
        id="chat-input"
        placeholder="Type your message..."
        className={`flex-1 resize-none bg-transparent outline-none text-sm leading-5 ${rows === 1 ? 'self-center' : 'self-start'}`}
        rows={1}
        onInput={handleInput}
        onKeyDown={handleKeyDown}
      />

      <PipelineConfigModal onConfigChange={handleConfigChange} />

      <button className="ml-2 p-2 rounded-lg hover:bg-muted transition" onClick={handleSend}>
        <Send className="w-4 h-4" />
      </button>
    </div>
  )
}
