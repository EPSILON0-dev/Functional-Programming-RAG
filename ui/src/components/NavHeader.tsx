import * as React from "react"
import {
    SidebarHeader,
    SidebarSeparator,
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
    SidebarTrigger,
} from "./ui/sidebar"

import {
    IconPencilPlus,
    IconCylinderPlus,
} from "@tabler/icons-react"

interface Props {
    open: boolean;
    onNewConversation: () => void;
    onNewDatabase: () => void;
}

export function NavHeader(props: Props): React.JSX.Element {
    return (
        <SidebarHeader>
            <div className="flex flex-row items-center">
                <SidebarTrigger />
                <span className={`mx-auto font-semibold text-base whitespace-nowrap overflow-hidden transition-all duration-100 ${props.open ? "opacity-100" : "opacity-0"}`}>PF Chatbot</span>
            </div>
            <SidebarSeparator className="opacity-0 mx-auto" />
            <SidebarMenu>
                <SidebarMenuItem>
                    <SidebarMenuButton
                        className="active:bg-gray-200 transition-all duration-50"
                        onClick={props.onNewDatabase}
                    >
                        <IconCylinderPlus className="mr-2" />
                        <span>New Database</span>
                    </SidebarMenuButton>
                </SidebarMenuItem>
                <SidebarMenuItem>
                    <SidebarMenuButton
                        className="active:bg-gray-200 transition-all duration-50"
                        onClick={props.onNewConversation}
                    >
                        <IconPencilPlus className="mr-2" />
                        <span>New Chat</span>
                    </SidebarMenuButton>
                </SidebarMenuItem>
            </SidebarMenu>
            <SidebarSeparator className={`${props.open ? "opacity-100" : "opacity-0"} mx-auto transition-all duration-100`} />
        </SidebarHeader>
    )
}
