# Chatbot przedmiotu programowanie funkcyjne

Asystent wspomagający naukę przedmiotu _Programowanie Funkcyjne_, oparty na **Retrieval-Augmented Generation (RAG)**, czyli podejściu łączącym wyszukiwanie w bazie wiedzy z generowaniem tekstu przez modele językowe.

## Funkcjonalności

### **Czat i Konwersacje**
- Tworzenie wielu niezależnych konwersacji z automatycznym zapisem historii
- Wysyłanie wiadomości i otrzymywanie odpowiedzi AI w czasie rzeczywistym
- Zmiana nazwy i usuwanie rozmów
- Pełna historia czatów z metadanymi (koszty generacji, znaczniki czasowe)

### **Integracja z Bazą Wiedzy**
- Przeglądanie kompletnej bazy wiedzy materiałów kursu Programowania Funkcyjnego
- Automatyczne wyszukiwanie istotnych artykułów na podstawie podobieństwa wektorów
- Wyświetlanie szczegółów artykułów i ich wykorzystania w odpowiedziach

### **Konta Użytkowników i Konfiguracja**
- Rejestracja użytkowników i autentykacja z tokenami JWT
- Zarządzanie kluczami API dostawców modeli (OpenRouter)
- Ustawienia konta: zmiana nazwy użytkownika, hasła
- Konfiguracja modelu i parametrów dla poszczególnych konwersacji

### **Aktualizacje w Czasie Rzeczywistym**
- Komunikacja WebSocket z transmisją wiadomości na żywo
- Monitorowanie etapów pipeline'u w czasie rzeczywistym
- Widok stanu "generowanie" podczas przetwarzania zapytania

## Szybki start

#### 1. Zbudowanie i uruchomienie aplikacji

Wykonaj poniższe komendy, aby zbudować obrazy Docker i uruchomić całą aplikację:

```bash
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up -d
```

Aplikacja będzie dostępna na **http://localhost:80**

#### 2. Konfiguracja konta i API

Następnie, w aplikacji webowej:

1. **Utwórz konto** — Załóż nowy rachunek użytkownika
2. **Zaloguj się** — Zaloguj się na nowo utworzone konto
3. **Przejdź do ustawień klucza API** — Kliknij ikonkę konta w lewym dolnym rogu a następnie wybierz "API Keys"
4. **Dodaj klucz API** — Dodaj swój klucz API dla dostawcy modeli (OpenRouter)
5. **Aktywuj klucz** — Wybierz dodany klucz API jako aktywny

Gotowe! Możesz teraz zacząć korzystać z chatbota.

## Potok Retrieval-Augmented Generation

1. **Wyodrębnianie tematu** (`1_topic_extraction.ex`)
 * Określa, czy wymagane jest przeszukanie bazy wiedzy
 * Normalizuje zapytanie tak, aby było niezależne od kontekstu
 * Zwraca: `{needs_kb, topic}`

2. **Odpowiedź bez wykorzystania bazy wiedzy** (`2_uninformed_response.ex`)
 * Generuje bazową odpowiedź bez dostępu do bazy wiedzy
 * Służy do porównania z odpowiedzią wygenerowaną z wykorzystaniem bazy

3. **Wyszukiwanie informacji** (`3_retrieval_stage.ex`)
 * Generuje osadzenia (embeddingi) dla zapytania
 * Przeprowadza wyszukiwanie wektorowe podobnych artykułów
 * Wykorzystuje embeddingi zarówno treści, jak i opisów

4. **Ponowne rangowanie wyników** (`4_rerank_stage.ex`)
 * Ponownie ocenia trafność odnalezionych artykułów
 * Przyznaje wynikom oceny i ustala ich kolejność
 * Obsługuje dwustopniowe rangowanie

5. **Generowanie odpowiedzi** (`5_generation.ex`)
 * Tworzy końcową odpowiedź na podstawie najwyżej ocenionych artykułów
 * Obsługuje generowanie równoległe (wiele kandydatów na odpowiedź)
 * Umożliwia konfigurację modelu, temperatury oraz opcji rozumowania

6. **Ponowne rangowanie odpowiedzi** (`6_response_rerank.ex`)
 * Weryfikuje i wybiera najlepszą odpowiedź spośród kandydatów
 * Przeprowadza końcową kontrolę jakości przed zwróceniem odpowiedzi

## Przepływ Pracy Wysyłania Wiadomości

1. **Użytkownik** pisze wiadomość w ChatView i klika wysłanie
2. **Frontend waliduje** wiadomość, autentykację, ID czatu
3. **HTTP POST** do `/api/chats/{chatId}/messages`
4. **Backend**:
   - Waliduje JWT token
   - Tworzy rekord Message (rola: "user")
   - Umieszcza `RunPipelineJob` w kolejce (Oban)
   - Zwraca `202 Accepted` natychmiast
5. **Async Job** — Worker wykonuje 6-etapowy pipeline:
   - Transmituje postęp via WebSocket
   - Tworzy rekord Message (rola: "assistant")
   - Transmituje nową wiadomość via WebSocket
6. **Frontend WebSocket** — Nasłuchuje aktualizacji:
   - Aktualizuje stan AppContext
   - ChatView re-renderuje z nowymi wiadomościami

## Stos Technologiczny

### **Frontend**
 * React - Biblioteka UI 
 * TypeScript - Język użyty we frontendzie
 * Vite - Build tool i dev server 
 * React Router - Routing po stronie klienta 
 * TailwindCSS - Stylizowanie
 * Sonner - Powiadomienia

### **Backend**
 * Phoenix - Framework webowy
 * Elixir - Runtime
 * Ecto - Komunikacja z bazą danych
 * Oban - Kolejkowanie i obsługa długich zadań
 * Joken - Tokeny JWT
 * pgvector - Wektorowa baza danych

## Wymagania Wstępne

Przed rozpoczęciem pracy upewnij się, że masz zainstalowane:

- **Elixir** ~> 1.15 (wraz z Erlang/OTP)
- **Node.js** (dla frontendu)
- **Docker** i Docker Compose (dla bazy danych PostgreSQL)
- **pdftotext** z pakietu `poppler-utils` (wymagane do importowania dokumentów PDF)

## Struktura Projektu

```
pf-rag/
├── api/           # Backend (Elixir/Phoenix)
├── ui/            # Frontend (React/TypeScript/Vite)
├── db/            # Konfiguracja Docker dla PostgreSQL z pgvector
└── docker-compose.yml  # Konfiguracja produkcyjna
```

## Inicjalna Konfiguracja

Przed pierwszym uruchomieniem:

```bash
# 1. Skopiuj plik ze zmiennymi środowiskowymi
cp .env.example .env

# 2. Zainstaluj zależności backendu
cd api && mix deps.get

# 3. Utwórz i skonfiguruj bazę danych
mix ecto.setup

# 4. Zainstaluj zależności frontendu
cd ../ui && npm install
```

## Komendy Deweloperskie

### Backend (`api/`)

```bash
cd api

# Serwer deweloperski (http://localhost:4000)
mix phx.server

# Zarządzanie bazą danych
mix ecto.migrate     # Uruchom migracje
mix ecto.reset       # Usuń i utwórz od nowa
```

### Frontend (`ui/`)

```bash
cd ui

# Serwer deweloperski (http://localhost:5173)
npm run dev
```

### Baza Danych

```bash
# Uruchomienie samej bazy danych
docker compose -f db/docker-compose-dev.yml up -d

# Zatrzymanie bazy danych
docker compose -f db/docker-compose-dev.yml down
```

## Endpointy API

### Autentykacja
| Metoda | Endpoint | Opis |
|--------|----------|------|
| POST | `/api/auth` | Logowanie |
| POST | `/api/auth/register` | Rejestracja |
| POST | `/api/auth/logout` | Wylogowanie |
| GET | `/api/auth/me` | Dane aktualnego użytkownika |
| PATCH | `/api/auth/me/username` | Zmiana nazwy użytkownika |
| PATCH | `/api/auth/me/password` | Zmiana hasła |
| DELETE | `/api/auth/me` | Usunięcie konta |
| GET | `/api/auth/wstoken` | Token dla WebSocket |

### Klucze API
| Metoda | Endpoint | Opis |
|--------|----------|------|
| GET | `/api/auth/keys` | Lista kluczy API |
| POST | `/api/auth/keys` | Dodanie klucza API |
| POST | `/api/auth/keys/selected` | Wybór aktywnego klucza |
| DELETE | `/api/auth/keys/:key_id` | Usunięcie klucza API |

### Czaty
| Metoda | Endpoint | Opis |
|--------|----------|------|
| GET | `/api/chats` | Lista czatów użytkownika |
| GET | `/api/chats/:chat_id` | Szczegóły czatu |
| GET | `/api/chats/:chat_id/messages` | Wiadomości w czacie |
| POST | `/api/chats/new` | Nowy czat z pierwszą wiadomością |
| POST | `/api/chats/:chat_id/messages` | Wyślij wiadomość |
| POST | `/api/chats/:chat_id/rename` | Zmień nazwę czatu |
| POST | `/api/chats/:chat_id/retry` | Ponów generowanie odpowiedzi |
| DELETE | `/api/chats/:chat_id` | Usuń czat |
| DELETE | `/api/chats/:chat_id/messages/:message_id` | Usuń wiadomość |

### Artykuły (Baza Wiedzy)
| Metoda | Endpoint | Opis |
|--------|----------|------|
| GET | `/api/articles` | Lista artykułów |
| GET | `/api/articles/:article_id` | Szczegóły artykułu |

### Inne
| Metoda | Endpoint | Opis |
|--------|----------|------|
| GET | `/api/health` | Health check |

## Zmienne Środowiskowe

Projekt używa pliku `.env` do konfiguracji. Skopiuj `.env.example` do `.env` i ustaw:

| Zmienna | Wymagana | Opis |
|---------|----------|------|
| `OPENROUTER_API_KEY` | Tak* | Klucz API do OpenRouter (używany przy importowaniu dokumentów) |
| `SECRET_KEY_BASE` | W produkcji | Klucz szyfrowania sesji (generuj: `mix phx.gen.secret`) |

\* Dla użytkowników końcowych klucz API jest przechowywany w bazie danych, ale do importowania dokumentów do bazy wiedzy wymagana jest zmienna środowiskowa.

Alternatywnie możesz ustawić zmienną w bieżącej sesji:
```bash
export OPENROUTER_API_KEY=twój_klucz
```

## Testy

### Backend

```bash
cd api
mix test
```

Frontend nie posiada obecnie skonfigurowanego zestawu testów.

## Struktura Bazy Danych

Aplikacja używa PostgreSQL z rozszerzeniem `pgvector` do przechowywania embeddingów wektorowych.

### Tabele

| Tabela | Opis |
|--------|------|
| `users` | Użytkownicy (id, username, password hash, selected_key_id, deleted_at) |
| `chats` | Sesje czatów (id, name, author_id, deleted_at) |
| `messages` | Wiadomości czatów (id, content, role, metadata, chat_id, author_id, deleted_at) |
| `apikeys` | Zaszyfrowane klucze API LLM (id, name, encrypted_key, owner_id) |
| `articles` | Artykuły bazy wiedzy z embeddingami (id, title, description, content, description_embedding, content_embedding, generation_cost, embedding_model) |
| `oban_jobs` | Kolejka zadań w tle (zarządzana przez Oban) |

**Uwaga:** Wszystkie dane użytkownika używają "miękkiego usuwania" (pole `deleted_at`) zamiast fizycznego usuwania rekordów.

## Uruchomienie Aplikacji

### Środowisko Produkcyjne

```bash
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up -d
# Aplikacja dostępa na localhost:80
```

### Środowisko deweloperskie

```bash
./start.sh
```

Skrypt uruchamia:
1. **PostgreSQL** w Docker'ze na sql://localhost:5432
2. **Backend Phoenix** na http://localhost:4000
3. **Frontend Vite** na http://localhost:5173

## Dodawanie Dokumentów do Bazy Wiedzy

Aplikacja umożliwia rozszerzanie bazy wiedzy o nowe dokumenty za pomocą Mix taska `rag.load`.

### Wymagania

* Ustawiona zmienna środowiskowa `OPENROUTER_API_KEY`
* Zainstalowane narzędzie `pdftotext` (z pakietu `poppler-utils`) dla plików PDF

### Użycie

```bash
cd api
mix rag.load path/to/document.pdf
```

Task obsługuje pliki PDF oraz pliki tekstowe (`.txt`). Dokument zostanie podzielony na fragmenty, które następnie są przetwarzane przez pipeline:

1. **Normalizacja i ocena trafności** - tekst jest czyszczony i oceniany pod kątem przydatności
2. **Generowanie tytułu i opisu** - tworzone są metadane dla każdego fragmentu
3. **Generowanie embeddingów** - tworzone są wektory dla wyszukiwania semantycznego
4. **Zapis do bazy danych** - artykuły są zapisywane w tabeli `articles`

### Konfiguracja (opcjonalna)

W `api/config/config.exs` można dostosować parametry przetwarzania.
