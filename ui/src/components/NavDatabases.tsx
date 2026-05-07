import * as React from "react"
import {
    SidebarGroup,
    SidebarGroupLabel,
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
    useSidebar,
} from "./ui/sidebar"

import {
    IconCylinder,
    IconDots,
} from "@tabler/icons-react"

import DatabaseSkeleton from "./DatabaseSkeleton";
import { Skeleton } from "./ui/skeleton";
import { AppContext } from "@/AppContext";
import { useNavigate } from "react-router-dom";

export function NavDatabases(): React.JSX.Element {
    const { open } = useSidebar();
    const ctx = React.useContext(AppContext);
    const databases = ctx?.state.databases ?? null;
    const navigate = useNavigate();

    return (
        <>
            {open &&
                <SidebarGroup>
                    <SidebarGroupLabel>
                        {databases ? <div className="select-none">Databases</div> : <Skeleton className="h-4 w-24" />}
                    </SidebarGroupLabel>
                    <SidebarMenu>
                        {databases ? databases.map((db) => (
                            <SidebarMenuItem className="group/item" key={db.id}>
                                <SidebarMenuButton
                                    className="w-full text-left active:bg-secondary transition-all duration-50"
                                    onClick={() => navigate(`/database/${db.id}`)}
                                >
                                    <IconCylinder className={`mr-2 ${open ? "opacity-100" : "opacity-0"} transition-all duration-100`} />
                                    <span className="whitespace-nowrap truncate">{db.name}</span>
                                    <div
                                        className="ml-auto mr-2 max-h-fit"
                                        onClick={(e) => { e.stopPropagation(); console.log(`Database ${db.name} options clicked`); }}
                                    >
                                        <IconDots className="opacity-40 max-w-0 group-hover/item:max-w-full hover:opacity-100 transition-all duration-100" />
                                    </div>
                                </SidebarMenuButton>
                            </SidebarMenuItem>
                        )) : (
                            <div className="pointer-events-none">
                                <SidebarMenuItem>
                                    <DatabaseSkeleton />
                                </SidebarMenuItem>
                            </div>
                        )}
                    </SidebarMenu>
                </SidebarGroup>
            }
        </>
    )
}
