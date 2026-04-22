"use client"

import { Button } from "@/components/ui/button"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { IconAdjustmentsHorizontal, IconChevronDown } from "@tabler/icons-react"

interface Props {
    presets: { label: string }[]
}

export function PresetSelectionDropdown({ presets }: Props): React.JSX.Element {
    return (
        <DropdownMenu>
            <DropdownMenuTrigger render={
                <Button variant="outline">
                    <IconAdjustmentsHorizontal />
                    {presets[0].label}
                    <IconChevronDown />
                </Button>
            } />
            <DropdownMenuContent className="w-60" align="start">
                {presets.map((preset) => (
                    <div key={preset.label}>
                        <DropdownMenuItem><IconAdjustmentsHorizontal />{preset.label}</DropdownMenuItem>
                    </div>
                ))}
            </DropdownMenuContent>
        </DropdownMenu>
    )
}
