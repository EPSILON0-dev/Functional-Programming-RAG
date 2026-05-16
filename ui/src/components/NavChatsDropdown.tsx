import { IconDots, IconPencil, IconTrash } from "@tabler/icons-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "./ui/button";
import { useContext, useState } from "react";
import { AppContext } from "@/AppContext";

export function NavChatsDropdown({ chatId }: { chatId: string }): React.JSX.Element {
  const ctx = useContext(AppContext);

  const [renameOpen, setRenameOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [newName, setNewName] = useState("");

  const handleRename = async (newChatName: string): Promise<void> => {
    fetch(`/api/chats/${chatId}/rename`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ new_name: newChatName }),
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error("Failed to rename chat");
        }
        ctx?.dispatch({ type: "REFRESH_CONVERSATIONS" });
      })
      .catch((error) => {
        console.error("Error renaming chat:", error);
      });
  };

  const handleDelete = async (): Promise<void> => {
    fetch(`/api/chats/${chatId}`, {
      method: "DELETE",
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error("Failed to delete chat");
        }
        ctx?.dispatch({ type: "REFRESH_CONVERSATIONS" });
      })
      .catch((error) => {
        console.error("Error deleting chat:", error);
      });
  };

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger nativeButton={false} render={
          <IconDots className="opacity-0 group-hover/item:opacity-40 hover:opacity-100 transition-opacity duration-100" />
        } />
        <DropdownMenuContent>
          <DropdownMenuGroup>
            <DropdownMenuItem onClick={() => setRenameOpen(true)}><IconPencil />Rename</DropdownMenuItem>
            <DropdownMenuItem className="text-red-500" onClick={() => setDeleteOpen(true)}><IconTrash />Delete</DropdownMenuItem>
          </DropdownMenuGroup>
        </DropdownMenuContent>
      </DropdownMenu >

      <Dialog open={renameOpen} onOpenChange={setRenameOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Rename Chat</DialogTitle>
          </DialogHeader>
          <input
            type="text"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            placeholder="Enter new chat name"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none"
          />
          <DialogFooter>
            <DialogClose render={<Button variant="outline">Cancel</Button>} />
            <Button onClick={() => {
              handleRename(newName);
              setRenameOpen(false);
              setNewName("");
            }}>
              Rename
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={deleteOpen} onOpenChange={setDeleteOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Chat</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this chat? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <DialogClose render={<Button variant="outline">Cancel</Button>} />
            <Button variant="destructive" onClick={() => {
              handleDelete();
              setDeleteOpen(false);
            }}>
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
