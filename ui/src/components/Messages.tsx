import * as React from "react"
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

import { IconAlertTriangle } from "@tabler/icons-react";

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

// TODO
export function GeneratingMessage({ message }: Props): React.JSX.Element {
  return (
    <div>
      <style>{`
        @keyframes shimmer {
          0% {
            background-position: -1000px 0;
          }
          100% {
            background-position: 1000px 0;
          }
        }
        .generating-text {
          animation: shimmer 2s infinite;
          background: linear-gradient(
            90deg,
            currentColor 0%,
            currentColor 40%,
            rgba(255, 255, 255, 0.3) 50%,
            currentColor 60%,
            currentColor 100%
          );
          background-size: 1000px 100%;
          -webkit-background-clip: text;
          background-clip: text;
          -webkit-text-fill-color: transparent;
        }
      `}</style>
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
      <style>{`
        @keyframes fadeIn {
          from {
            opacity: 0;
          }
          to {
            opacity: 1;
          }
        }
        .assistant-message {
          animation: fadeIn 0.2s ease-in;
        }
      `}</style>
      <div className="assistant-message">
        <ReactMarkdown remarkPlugins={[remarkGfm]}>
          {message}
        </ReactMarkdown>
      </div>
      <div className="h-16" />
    </div>
  )
}

export function ErrorMessage({ message }: Props): React.JSX.Element {
  return (
    <div>
      <div className="outline-1 outline-destructive/50 rounded-2xl px-4 py-2 max-w-2xl mr-auto w-fit">
        <IconAlertTriangle size="20" className="text-destructive inline-block mr-2" />
        {message}
      </div>
      <div className="h-8" />
    </div>
  )
}
