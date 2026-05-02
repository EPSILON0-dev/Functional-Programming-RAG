import * as React from "react"
import {
    SidebarHeader,
    SidebarSeparator,
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
    SidebarTrigger,
    useSidebar,
} from "./ui/sidebar"

import {
    IconPencilPlus,
    IconCylinderPlus,
} from "@tabler/icons-react"
import { useNavigate } from "react-router-dom";

export function NavHeader(): React.JSX.Element {
    const { open } = useSidebar();
    const navigate = useNavigate();
    return (
        <SidebarHeader>
            <div className="flex flex-row items-center">
                <SidebarTrigger />
                <span className={`select-none mx-auto font-semibold text-base whitespace-nowrap overflow-hidden transition-all duration-100 ${open ? "opacity-100" : "opacity-0"}`}>PF Chatbot</span>
            </div>
            <SidebarSeparator className="opacity-0 mx-auto" />
            <SidebarMenu>
                <SidebarMenuItem>
                    <SidebarMenuButton
                        className="active:bg-secondary transition-all duration-50"
                    >
                        <IconCylinderPlus className="mr-2" />
                        <span>New Database</span>
                    </SidebarMenuButton>
                </SidebarMenuItem>
                <SidebarMenuItem>
                    <SidebarMenuButton
                        className="active:bg-secondary transition-all duration-50"
                        onClick={() => navigate("/")}
                    >
                        <IconPencilPlus className="mr-2" />
                        <span>New Chat</span>
                    </SidebarMenuButton>
                </SidebarMenuItem>
            </SidebarMenu>
            <SidebarSeparator className={`${open ? "opacity-100" : "opacity-0"} mx-auto transition-all duration-100`} />
        </SidebarHeader>
    )
}
