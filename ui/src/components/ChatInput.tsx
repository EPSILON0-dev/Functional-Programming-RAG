import { Send } from "lucide-react"

export function ChatInput() {
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
      console.log("Send message:", message)
      input.value = ""
    }
  }

  return (
    <div className="border rounded-xl flex items-center px-3 py-2 bg-background">
      <textarea id="chat-input"
        placeholder="Type your message..."
        className="flex-1 resize-none bg-transparent outline-none text-sm"
        rows={1}
        onKeyDown={handleKeyDown}
      />

      <button className="ml-2 p-2 rounded-lg hover:bg-muted transition" onClick={handleSend}>
        <Send className="w-4 h-4" />
      </button>
    </div>
  )
}
