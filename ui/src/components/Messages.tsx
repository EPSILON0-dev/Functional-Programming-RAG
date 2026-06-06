import * as React from "react"
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import "@/components/Messages.css"

import { IconAlertTriangle, IconTrash, IconRefresh } from "@tabler/icons-react";
import { Button } from "@/components/ui/button";

interface Props {
  message: string;
}

export function UserMessage({ message }: Props): React.JSX.Element {
  return (
    <div>
      <div className="bg-secondary rounded-2xl px-4 py-2 max-w-2xl ml-auto w-fit">{message}</div>
      <div className="h-8" />
    </div>
  )
}

export function GeneratingMessage({ message }: Props): React.JSX.Element {
  return (
    <div>
      <div className="flex gap-3">
        <div className="generating-text flex-1 py-auto">
          {message}
        </div>
      </div>
      <div className="h-8" />
    </div>
  )
}

export function AssistantMessage({ message }: Props): React.JSX.Element {
  return (
    <div>
      <div className="assistant-message">
        <ReactMarkdown remarkPlugins={[remarkGfm]}>
          {message}
        </ReactMarkdown>
      </div>
      <div className="h-16" />
    </div>
  )
}

export function ErrorMessage({
  message,
  details,
  isLastMessage = false,
  onAction,
}: {
  message: string,
  details?: string,
  isLastMessage?: boolean,
  onAction?: () => void,
}): React.JSX.Element {
  return (
    <div>
      <div className="flex gap-2 items-start max-w-2xl mr-auto w-fit">
        <div className="outline-1 outline-destructive/50 rounded-2xl px-4 py-2 flex-1">
          <IconAlertTriangle size="20" className="text-destructive inline-block mr-2" />
          {message}
          {details && <div className="text-destructive text-xs mt-1">{details}</div>}
        </div>
        <div className="flex gap-1 pt-1">
          {isLastMessage && onAction && (
            <Button
              size="sm"
              variant="outline"
              onClick={onAction}
              className="px-2 h-8"
              title="Retry generation"
            >
              <IconRefresh size={16} />
            </Button>
          )}
          {!isLastMessage && onAction && (
            <Button
              size="sm"
              variant="outline"
              onClick={onAction}
              className="px-2 h-8"
              title="Delete message"
            >
              <IconTrash size={16} />
            </Button>
          )}
        </div>
      </div>
      <div className="h-8" />
    </div>
  )
}
