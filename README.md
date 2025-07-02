# Troova

![Logo di Troova](assets/icons/logo_foreground.png)

**Troova** è un'applicazione mobile cross-platform progettata per connettere persone che offrono e cercano servizi a livello locale. Sviluppata con Flutter, l'app offre un'esperienza utente fluida e reattiva su Android, iOS e altre piattaforme supportate.

---

## 📜 Indice

- [Riguardo al Progetto](#-riguardo-al-progetto)
- [✨ Funzionalità Principali](#-funzionalità-principali)
- [🛠️ Tecnologie e Architettura](#️-tecnologie-e-architettura)
  - [Pila Tecnologica](#pila-tecnologica)
  - [Architettura](#architettura)
- [🚀 Come Iniziare](#-come-iniziare)
  - [Prerequisiti](#prerequisiti)
  - [Installazione](#installazione)
- [🔧 Configurazione](#-configurazione)
- [🤝 Contribuire](#-contribuire)
- [📄 Licenza](#-licenza)

---

## 📜 Riguardo al Progetto

L'obiettivo di Troova è creare un ecosistema semplice e intuitivo dove gli utenti possono pubblicare annunci per i servizi che offrono (es. ripetizioni, giardinaggio, consulenze) e, allo stesso tempo, trovare e contattare professionisti e fornitori di servizi nella loro zona. L'app include funzionalità di chat in tempo reale, gestione degli annunci e profili utente dettagliati.

---

## ✨ Funzionalità Principali

- **Creazione e Gestione Annunci**: Gli utenti possono creare annunci dettagliati per i servizi che offrono, modificarli e gestirli dal proprio profilo.
- **Ricerca e Filtri**: Trova servizi in base a categorie, parole chiave e posizione geografica.
- **Profili Utente**: Ogni utente ha un profilo con informazioni di contatto, competenze e gli annunci pubblicati.
- **Chat Integrata**: Comunica in modo sicuro con altri utenti direttamente all'interno dell'app per discutere dettagli e accordi.
- **Registrazione e Autenticazione**: Accesso facile e sicuro tramite email/password e account Google.
- **Supporto Utente**: Una sezione dedicata per ricevere supporto e assistenza.

---

## 🛠️ Tecnologie e Architettura

### Pila Tecnologica

- **Framework**: [Flutter](https://flutter.dev/) (SDK Version) - Per lo sviluppo di un'unica codebase per Android, iOS, Web e Desktop.
- **Linguaggio**: [Dart](https://dart.dev/)
- **Backend & Database**: [Firebase](https://firebase.google.com/)
  - **Firestore**: Come database NoSQL per la gestione di annunci, chat e dati utente.
  - **Firebase Authentication**: Per l'autenticazione degli utenti (Email/Password, Google Sign-In).
  - **Firebase Storage**: (Potenzialmente) per l'archiviazione di immagini per profili e annunci.
- **API Esterne**:
  - **Google Places API**: Per la ricerca e l'autocompletamento degli indirizzi durante la registrazione e la creazione di annunci.
- **Gestione dello Stato**: [Provider / BLoC / Riverpod / GetX] - *Inserire la libreria specifica utilizzata nel progetto.*

### Architettura

- **Cross-Platform**: L'architettura del progetto è basata su Flutter, garantendo che l'applicazione possa essere compilata nativamente per più piattaforme da un'unica codebase.
- **Struttura a Moduli (Feature-based)**: Il codice sorgente nella directory `lib/` è organizzato per funzionalità (es. `chat`, `serviceAdv`, `signInUp`), promuovendo la manutenibilità e la scalabilità del codice.
- **UI Component-Based**: L'interfaccia utente è costruita utilizzando un sistema di widget riutilizzabili (`customWidgets`), seguendo i principi di progettazione di Flutter.
- **Backend as a Service (BaaS)**: L'applicazione si affida pesantemente ai servizi di Firebase, riducendo la necessità di un backend custom. La logica di business principale risiede nell'app client, che comunica direttamente con le API di Firebase.
- **Services Layer**: La logica di interazione con servizi esterni (come Firestore) è astratta in classi di servizio (es. `FirestoreService.dart`), separando la logica di business dalla manipolazione diretta dei dati.

---

## 🚀 Come Iniziare

Per ottenere una copia locale del progetto e farlo funzionare, segui questi semplici passaggi.

### Prerequisiti

Assicurati di avere installato:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Un editor di codice come [VS Code](https://code.visualstudio.com/) o [Android Studio](https://developer.android.com/studio)
- Un account [Firebase](https://firebase.google.com/)

### Installazione

1. **Clona il repository**
   ```sh
   git clone https://github.com/tuo-username/Troova.git
   ```
2. **Naviga nella directory del progetto**
   ```sh
   cd Troova
   ```
3. **Configura Firebase**
   - Crea un nuovo progetto sulla [console di Firebase](https://console.firebase.google.com/).
   - Aggiungi un'app Android e/o iOS al tuo progetto Firebase.
   - **Per Android**: Scarica il file `google-services.json` e posizionalo in `android/app/`.
   - **Per iOS**: Scarica il file `GoogleService-Info.plist` e configuralo nel tuo progetto Xcode.
   - Abilita i servizi necessari come **Firestore Database** e **Authentication** (con i provider Google e Email/Password).

4. **Installa le dipendenze Dart**
   ```sh
   flutter pub get
   ```

5. **Avvia l'applicazione**
   ```sh
   flutter run
   ```

---

## 🔧 Configurazione

Il progetto potrebbe richiedere delle chiavi API o configurazioni di ambiente specifiche.
- Un file `.env` è presente nella cartella `assets/`. Assicurati di popolarlo con le variabili d'ambiente necessarie, come le chiavi per l'API di Google Places.
  ```
  GOOGLE_MAPS_API_KEY=LA_TUA_CHIAVE_API
  ```
- Il file `assets/firebase_service_account.json` è utilizzato per l'accesso admin al backend. **NON INCLUDERE QUESTO FILE IN REPOSITORY PUBBLICI**. Deve essere generato dal tuo progetto Firebase e gestito in modo sicuro.

---

## 🤝 Contribuire

I contributi sono ciò che rende la comunità open source un posto fantastico per imparare, ispirare e creare. Qualsiasi contributo tu faccia sarà **molto apprezzato**.

1.  Forka il Progetto
2.  Crea il tuo Branch per la feature (`git checkout -b feature/AmazingFeature`)
3.  Committa le tue modifiche (`git commit -m 'Add some AmazingFeature'`)
4.  Pusha sul Branch (`git push origin feature/AmazingFeature`)
5.  Apri una Pull Request

---

## 📄 Licenza

Distribuito sotto la Licenza [MIT / Apache 2.0 / etc.]. Vedi `LICENSE` per maggiori informazioni.