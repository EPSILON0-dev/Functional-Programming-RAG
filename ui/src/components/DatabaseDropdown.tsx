"use client"

import { Button } from "@/components/ui/button"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { IconChevronDown, IconCylinder } from "@tabler/icons-react"
import type { NamedIdentifier } from "@/types"

interface Props {
    databases: NamedIdentifier[] | null;
    selectedDatabase: NamedIdentifier | null;
    onSelectDatabase: (database: NamedIdentifier) => void;
};

export function DatabaseDropdown(props: Props): React.JSX.Element {
    return (
        <div className={`${props.databases === null ? "pointer-events-none" : ""}`}>
            <DropdownMenu >
                <DropdownMenuTrigger render={
                    <Button variant="outline">
                        <IconCylinder />
                        {props.databases === null ? "Loading ..." :
                            (props.selectedDatabase === null ? "Select Database" :
                                props.databases !== null && props.databases?.find((x) => x.id === props.selectedDatabase?.id)?.label)}
                        <IconChevronDown />
                    </Button>
                } />
                <DropdownMenuContent className="w-60" align="start">
                    {props.databases?.map((db) => (
                        <div key={db.label}>
                            <DropdownMenuItem
                                onClick={() => { props.onSelectDatabase(db) }}
                            >
                                <IconCylinder />{db.label}
                            </DropdownMenuItem>
                        </div>
                    ))}
                </DropdownMenuContent>
            </DropdownMenu>
        </div>
    )
}
