import * as React from "react"
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import "@/components/Messages.css"

import { IconAlertTriangle, IconTrash, IconRefresh, IconInfoCircle, IconCopy, IconCheck } from "@tabler/icons-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import type { Message } from "@/types/types";
import { useNavigate } from "react-router-dom";

interface Props {
  message: string;
}

interface AssistantMessageProps {
  message: Message;
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

export function AssistantMessage({ message }: AssistantMessageProps): React.JSX.Element {
  const [isHovered, setIsHovered] = React.useState(false);
  const [showInfo, setShowInfo] = React.useState(false);
  const [copied, setCopied] = React.useState(false);
  const navigate = useNavigate();

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(message.content);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy message:", err);
    }
  };

  const metadata = message.metadata;
  const articles = metadata?.articles || [];
  const cost = metadata?.total_cost;
  const kbUsed = metadata?.kb_used;
  const articlesRetrieved = metadata?.articles_retrieved;
  const articlesUsed = metadata?.articles_used;

  return (
    <>
      <div
        className="group relative mb-4"
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        <div className="assistant-message">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>
            {message.content}
          </ReactMarkdown>
        </div>

        {/* Action buttons - appear on hover */}
        <div
          className={`absolute -bottom-8 left-0 flex gap-1 transition-opacity duration-150 ${isHovered ? "opacity-100" : "opacity-0"
            }`}
        >
          <Button
            size="icon-sm"
            variant="ghost"
            onClick={() => setShowInfo(true)}
            className="h-7 w-7"
            title="Message info"
          >
            <IconInfoCircle size={16} />
          </Button>
          <Button
            size="icon-sm"
            variant="ghost"
            onClick={handleCopy}
            className="h-7 w-7"
            title={copied ? "Copied!" : "Copy message"}
          >
            {copied ? <IconCheck size={16} className="text-green-500" /> : <IconCopy size={16} />}
          </Button>
        </div>
      </div>
      <div className="h-12" />

      {/* Info Modal */}
      <Dialog open={showInfo} onOpenChange={setShowInfo}>
        <DialogContent className="max-w-xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Message Info</DialogTitle>
            <DialogDescription>
              Details about how this response was generated
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 mt-4">
            {/* Cost Section */}
            {cost !== undefined && (
              <div>
                <h4 className="text-sm font-medium mb-1">Cost</h4>
                <p className="text-sm text-muted-foreground">
                  ${cost.toFixed(6)}
                </p>
              </div>
            )}

            {/* KB Usage Section */}
            {kbUsed !== undefined && (
              <div>
                <h4 className="text-sm font-medium mb-1">Knowledge Base</h4>
                <p className="text-sm text-muted-foreground">
                  {kbUsed
                    ? `Used (${articlesRetrieved || 0} retrieved, ${articlesUsed || 0} used)`
                    : "Not used"}
                </p>
              </div>
            )}

            {/* Articles Section */}
            {articles.length > 0 && (
              <div>
                <h4 className="text-sm font-medium mb-2">
                  Referenced Articles ({articles.length})
                </h4>
                <ul className="space-y-2">
                  {articles.map((article, index) => (
                    <li
                      key={article.id}
                      className="text-sm text-muted-foreground bg-muted rounded-md px-3 py-2 hover:bg-muted/80 transition-colors cursor-pointer"
                      onClick={() => navigate(`/explore/${article.id}`)}
                    >
                      <span className="font-medium text-foreground">
                        {index + 1}. {article.title}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {articles.length === 0 && kbUsed && (
              <div>
                <h4 className="text-sm font-medium mb-1">Referenced Articles</h4>
                <p className="text-sm text-muted-foreground">No articles referenced</p>
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </>
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
