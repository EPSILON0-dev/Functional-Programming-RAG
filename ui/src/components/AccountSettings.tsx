import { useContext, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Field, FieldGroup } from "@/components/ui/field";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { AppContext } from "@/AppContext";
import { useQuery } from "@tanstack/react-query";
import { TrashIcon } from "lucide-react";

interface AccountSettingsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

type Panel = "api-keys";

export function AccountSettingsDialog({ open, onOpenChange }: AccountSettingsDialogProps) {
  const ctx = useContext(AppContext);
  const user = ctx?.state.currentUser;

  const keys = useQuery({
    queryKey: ["apiKeys"],
    queryFn: async () => {
      const res = await fetch("/api/auth/keys");
      if (!res.ok) throw new Error("Failed to fetch API keys");
      return res.json();
    },
  });

  const [panel, setPanel] = useState<Panel>("api-keys");

  const [newApiKeyName, setNewApiKeyName] = useState("");
  const [newApiKeySecret, setNewApiKeySecret] = useState("");
  const [apiKeyError, setApiKeyError] = useState<string | null>(null);
  const [apiKeySuccess, setApiKeySuccess] = useState(false);

  function resetState() {
    setPanel("api-keys");
    setNewApiKeyName("");
    setNewApiKeySecret("");
    setApiKeyError(null);
    setApiKeySuccess(false);
  }

  function handleOpenChange(next: boolean) {
    onOpenChange(next);
    if (!next) resetState();
  }

  function handleSelectKey(selectedKeyId: string) {
    fetch("/api/auth/keys/selected", {
      "method": "POST",
      "headers": { "Content-Type": "application/json" },
      "body": JSON.stringify({ key_id: selectedKeyId }),
    })
      .then((res) => {
        if (!res.ok) {
          return res.json().then((data) => {
            throw new Error(data.error || "Failed to set selected API key");
          });
        }
        return res.json();
      })
      .then(() => {
        keys.refetch();
      })
      .catch((err) => {
        console.error("Error setting selected API key:", err);
      });
  }

  function handleAddApiKey(e: React.FormEvent) {
    e.preventDefault();
    setApiKeyError(null);

    fetch("/api/auth/keys", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: newApiKeyName, key: newApiKeySecret }),
    })
      .then((res) => {
        if (!res.ok) {
          return res.json().then((data) => {
            throw new Error(data.error || "Failed to set API key");
          });
        }
        return res.json();
      })
      .then(() => {
        setApiKeySuccess(true);
        keys.refetch();
      })
      .catch((err) => {
        setApiKeyError(err.message);
        setApiKeySuccess(false);
      });
  }

  function handleDeleteKey(selectedKeyId: string) {
    fetch(`/api/auth/keys/${selectedKeyId}`, {
      "method": "DELETE",
      "headers": { "Content-Type": "application/json" },
    })
      .then((res) => {
        if (!res.ok) {
          return res.json().then((data) => {
            throw new Error(data.error || "Failed to delete API key");
          });
        }
        return res.json();
      })
      .then(() => {
        keys.refetch();
      })
      .catch((err) => {
        console.error("Error deleting API key:", err);
      });
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Account Settings</DialogTitle>
          <DialogDescription>
            Signed in as{" "}
            <span className="font-medium text-foreground">{user?.username}</span>
          </DialogDescription>
        </DialogHeader>

        {/* Panel tabs */}
        <div className="flex gap-2">
          <Button
            size="sm"
            variant={panel === "api-keys" ? "default" : "outline"}
            onClick={() => setPanel("api-keys")}
          >
            OpenRouter API Key
          </Button>
        </div>

        {panel === "api-keys" && (
          <form onSubmit={handleAddApiKey}>
            <FieldGroup>
              <ul className="space-y-1">
                <Label className="pb-2">Select API Key</Label>
                {Array.isArray(keys.data?.api_keys) && keys.data.api_keys.length > 0 ? keys.data.api_keys.map((key: any) => (
                  <li
                    key={key.id}
                    className={`flex items-center justify-between rounded-md ${key.id === keys.data.selected_key_id
                      ? "bg-green-100 text-green-800 dark:bg-green-800 dark:text-green-100"
                      : "bg-muted text-muted-foreground active:bg-secondary hover:bg-secondary/80"
                      }`}
                    onClick={() => { handleSelectKey(key.id) }}
                  >
                    <span className="ml-4 mr-2 text-sm select-none">{key.name}</span>
                    <span className="mx-2 font-mono text-xs select-none">{key.key}</span>
                    <Button
                      variant="ghost"
                      className="mx-1 my-1 w-8 h-8"
                      onClick={() => { handleDeleteKey(key.id) }}
                    >
                      <TrashIcon />
                    </Button>
                  </li>
                )) : <small><i>Add a key to start!</i></small>}
                {Array.isArray(keys.data?.api_keys) && keys.data.api_keys.length > 0 && keys.data.api_keys.every((key: any) => key.id !== keys.data.selected_key_id) && (
                  <li className="flex items-center justify-between rounded-md bg-yellow-100 text-yellow-800 dark:bg-yellow-800 dark:text-yellow-100">
                    <span className="ml-4 mr-2 text-sm select-none">No key selected</span>
                  </li>
                )}
              </ul>
            </FieldGroup>
            <FieldGroup className="pt-4">
              <Field>
                <Label>New API Key Name</Label>
                <Input
                  id="new-api-key-name"
                  placeholder="Key name"
                  autoComplete="off"
                  value={newApiKeyName}
                  onChange={(e) => setNewApiKeyName(e.target.value)}
                  required
                />
                <Input
                  id="new-api-key-secret"
                  placeholder="sk-or-v1-..."
                  autoComplete="off"
                  value={newApiKeySecret}
                  onChange={(e) => setNewApiKeySecret(e.target.value)}
                  required
                />
              </Field>
              <Button type="submit" className="mt-2">Add API Key</Button>
            </FieldGroup>
            {apiKeyError && (
              <p className="mt-2 text-sm text-destructive">{apiKeyError}</p>
            )}
            {apiKeySuccess && (
              <p className="mt-2 text-sm text-green-600 dark:text-green-400">
                API Key updated successfully.
              </p>
            )}
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
}
