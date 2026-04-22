import * as React from "react"
import {
    SidebarGroup,
    SidebarGroupLabel,
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
} from "./ui/sidebar"

import {
    IconDots,
} from "@tabler/icons-react"
import type { ConversationIdentifier } from "@/types";

interface NavConversationsInterface {
    conversations: ConversationIdentifier[];
    onConversationSelect: (conversationId: string) => void;
}

export function NavConversations(props: NavConversationsInterface): React.JSX.Element {
    return (
        <SidebarGroup>
            <SidebarGroupLabel>Conversations</SidebarGroupLabel>
            <SidebarMenu>
                {props.conversations.map((conv) => (
                    <SidebarMenuItem className="group/item" key={conv.id}>
                        <SidebarMenuButton
                            className="active:bg-gray-200 transition-all duration-50"
                            onClick={() => props.onConversationSelect(conv.id)}
                        >
                            <span className="whitespace-nowrap truncate">{conv.label}</span>
                            <div
                                className="ml-auto mr-2 max-h-fit"
                                onClick={(e) => { e.stopPropagation(); console.log(`Conversation ${conv.label} options clicked`); }}
                            >
                                <IconDots className="opacity-40 max-w-0 group-hover/item:max-w-full hover:opacity-100 transition-all duration-100" />
                            </div>
                        </SidebarMenuButton>
                    </SidebarMenuItem>
                ))}
            </SidebarMenu>
        </SidebarGroup>
    )
}
