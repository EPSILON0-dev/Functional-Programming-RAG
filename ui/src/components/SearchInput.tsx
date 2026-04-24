import React from "react"
import { Search } from "lucide-react"

interface Props {
  placeholderText?: string;
  onMessageSent: (message: string) => Promise<void> | null;
}

export function SearchInput(props: Props): React.JSX.Element {
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
      props.onMessageSent(message)
    }
  }

  return (
    <div className="border rounded-xl flex items-center px-3 py-2 bg-background">
      <textarea id="chat-input"
        placeholder={props.placeholderText ?? "Type your search query..."}
        className="flex-1 resize-none bg-transparent outline-none text-sm"
        rows={1}
        onKeyDown={handleKeyDown}
      />

      <button className="ml-2 p-2 rounded-lg hover:bg-muted transition" onClick={handleSend}>
        <Search className="w-4 h-4 text-muted-foreground" />
      </button>
    </div>
  )
}
