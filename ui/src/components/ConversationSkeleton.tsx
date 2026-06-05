import * as React from "react"
import {
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
} from "./ui/sidebar"

import { Skeleton } from "./ui/skeleton"

export function ConversationSkeleton(): React.JSX.Element {
    const rows = Array.from({ length: 4 })
    return (
        <SidebarMenu>
            {rows.map((_, i) => (
                <SidebarMenuItem key={i}>
                    <SidebarMenuButton className="cursor-default">
                        <div className="w-full flex items-center gap-2">
                            <div className="flex-1">
                                <Skeleton className="h-4 w-32" />
                            </div>
                            <div className="ml-auto">
                                <Skeleton className="h-4 w-6" />
                            </div>
                        </div>
                    </SidebarMenuButton>
                </SidebarMenuItem>
            ))}
        </SidebarMenu>
    )
}

export default ConversationSkeleton
