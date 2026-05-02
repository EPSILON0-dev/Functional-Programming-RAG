# Chatbot przedmiotu „Programowanie Funkcyjne"

Asystent wspomagający naukę przedmiotu _Programowanie Funkcyjne_. Odpowiada na pytania dotyczące materiału wykładowego, ćwiczeń i zadań, opierając się na dostarczonych dokumentach kursu.

---

## Funkcjonalności

- Rozmowa z modelem językowym w interfejsie czatu
- Trwała pamięć konwersacji dzięki automatycznemu kompaktowaniu historii
- Wybór modelu językowego dla poszczególnych etapów przetwarzania (wyszukiwanie, generacja)
- Przeglądanie historii poprzednich rozmów
- Prosty system kont użytkowników z oddzielną historią dla każdego z nich
- Obsługa wielu niezależnych baz dokumentów
- Estymacja kosztów wykorzystania modeli językowych

---

## Architektura

Projekt oparty jest na podejściu **RAG** (_Retrieval Augmented Generation_), które łączy przeszukiwenie bazy danych z generowaniem tekstu przez model językowy.

### Indeksowanie dokumentów

1. Dokumenty są konwertowane do formatu tekstowego (Markdown); opcjonalnie obrazy zastępowane są opisem tekstowym.
2. Tekst dzielony jest na fragmenty odpowiadające pojedynczym akapitom.
3. Fragmenty niekompletne, błędne lub nieistotne są odfiltrowywane.
4. Dla każdego fragmentu generowane są tytuł i streszczenie.
5. Fragment wraz z metadanymi i wektorem osadzeń zapisywany jest w bazie danych.

### Wyszukiwanie

1. Model ocenia, czy odpowiedź na zapytanie wymaga sięgnięcia do bazy dokumentów.
2. Zapytanie jest przepisywane tak, by było niezależne od kontekstu poprzednich wiadomości.
3. Generowane są embeddingi oraz słowa kluczowe użyte do przeszukania bazy.
4. Wyniki są oceniane pod kątem trafności, a najlepsze fragmenty wybierane jako kontekst.

### Generowanie odpowiedzi

1. Uruchamiane jest wyszukiwanie opisane powyżej.
2. Model generuje odpowiedź na podstawie zapytania i pobranych fragmentów.
3. Gdy historia konwersacji przekroczy dopuszczalny rozmiar, jest automatycznie kompaktowana.

---

## Stos technologiczny

| Warstwa | Technologia | Rola |
|---|---|---|
| Frontend | **React** + **TypeScript** | Interfejs użytkownika (okno czatu) |
| Logika aplikacji | **TypeScript**/**PureScript** | Funkcyjna logika biznesowa i integracja z API |
| Baza danych | **PostgreSQL** + **pgvector** | Przechowywanie dokumentów i wektorów osadzeń |
| Przygotowanie dokumentów | **PyMuPDF** + **pandoc** | Konwertowanie dokumentów do markdown'a |
| Modele językowe | **OpenRouter** / **Ollama** | Generowanie odpowiedzi i tworzenie osadzeń |
