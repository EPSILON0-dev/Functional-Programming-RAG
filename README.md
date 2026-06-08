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

### **Zmienne Środowiskowe**

* `OPENROUTER_API_KEY` - Klucz używany podczas przygotowywania i osadzania artukułów

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
