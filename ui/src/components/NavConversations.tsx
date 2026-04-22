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
import type { NamedIdentifier } from "@/types";
import { ConversationSkeleton } from "./ConversationSkeleton";
import { Skeleton } from "./ui/skeleton";

interface NavConversationsInterface {
    open: boolean;
    conversations: NamedIdentifier[] | null;
    onConversationSelect: (conversation: NamedIdentifier) => void;
}

export function NavConversations(props: NavConversationsInterface): React.JSX.Element {
    return (
        <>
            {props.open && <SidebarGroup>
                <SidebarGroupLabel>
                    {props.conversations ? "Conversations" : <Skeleton className="h-4 w-24" />}
                </SidebarGroupLabel>
                <SidebarMenu>
                    {props.conversations ? props.conversations.map((conv) => (
                        <SidebarMenuItem className="group/item" key={conv.id}>
                            <SidebarMenuButton
                                className="active:bg-gray-200 transition-all duration-50"
                                onClick={() => props.onConversationSelect(conv)}
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
                    )) : (
                        <SidebarMenuItem>
                            <div className="pointer-events-none">
                                <ConversationSkeleton />
                            </div>
                        </SidebarMenuItem>
                    )}
                </SidebarMenu>
            </SidebarGroup>
            }
        </>
    )
}
