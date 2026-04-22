import * as React from "react"
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface AssistantMessageProps {
    message: string;
}

export function AssistantMessage({ message }: AssistantMessageProps): React.JSX.Element {
    return (
        <div>
            <ReactMarkdown remarkPlugins={[remarkGfm]}>
                {message}
            </ReactMarkdown>
            <div className="h-16" />
        </div>
    )
}
