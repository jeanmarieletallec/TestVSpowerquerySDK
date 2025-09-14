// Requête Maîtresse : Version finale avec la fonction DateTimeZone corrigée
let
    // --- PARTIE 0 : Utilisation directe des paramètres (inchangée) ---
    TokenValue = Token,
    CompanyIdValue = Text.From(CompanyId),
    StartDateValue = StartDate,
    EndDateValue = EndDate,

    // --- PARTIE 1 : Créer la demande d'export (inchangée) ---
    UrlCreationExport = "https://app.pennylane.com/api/external/v2/exports/analytical_general_ledgers",
    CorpsRecord = [period_start = StartDateValue, period_end = EndDateValue],
    CorpsEnJson = Json.FromValue(CorpsRecord),
    QueryRecord = [customer_firm_id = CompanyIdValue],
    ReponseCreationExport = Json.Document(Web.Contents(UrlCreationExport, [Headers = [#"Authorization" = "Bearer " & TokenValue, #"Content-Type" = "application/json"], Query = QueryRecord, Content = CorpsEnJson])),
    IdExportationObtenu = Text.From(ReponseCreationExport[id]),

    // --- PARTIE 2 : Boucle d'attente AVEC DÉPENDANCE FORCÉE ---
    UrlStatut = "https://app.pennylane.com/api/external/v2/exports/analytical_general_ledgers/" & IdExportationObtenu,
    EnTetesStatut = [ #"Authorization" = "Bearer " & TokenValue ],
    QueryStatutBase = [ #"customer_firm_id" = CompanyIdValue ],
    maxTentatives = 120,
    delai = #duration(0,0,0,10),

    ListeDesEtats = List.Generate(
        // Étape initiale
        () => [
            tentative = 0, 
            reponse = Json.Document(Web.Contents(UrlStatut, [Headers=EnTetesStatut, Query = QueryStatutBase]))
        ],

        // Condition pour CONTINUER la boucle
        each [tentative] < maxTentatives and [reponse][status]? <> "ready",

        // Prochaine étape
        each 
            let
                // CORRECTION : Utilisation de DateTimeZone.UtcNow() au lieu de DateTime.UtcNow()
                valeurPause = Function.InvokeAfter(() => DateTime.ToText(DateTimeZone.UtcNow(), "yyyy-MM-dd-hh-mm-ss-fff"), delai),
                
                nouvelleReponse = Json.Document(Web.Contents(UrlStatut, [
                    Headers=EnTetesStatut, 
                    Query = QueryStatutBase & [cachebuster = valeurPause]
                ]))
            in
                [tentative = [tentative] + 1, reponse = nouvelleReponse],

        // Ce que l'on garde de chaque étape
        each [reponse]
    ),
    
    ReponseFinaleJson = List.Last(ListeDesEtats),

    // --- PARTIE 3 : Téléchargement et traitement du fichier final (inchangée) ---
    Resultat = if ReponseFinaleJson[status]? = "ready" then
        let
            UrlFichierFinal = ReponseFinaleJson[file_url],
            FichierBinaire = Web.Contents(UrlFichierFinal),
            ClasseurImporte = Excel.Workbook(FichierBinaire, null, true),
            PremiereFeuille = ClasseurImporte{0}[Data],
            EnTetesPromus = Table.PromoteHeaders(PremiereFeuille, [PromoteAllScalars=true])
        in
            EnTetesPromus
    else
        error "L'export n'a pas pu être généré dans le temps imparti (20 minutes). Statut final : " & Text.From(ReponseFinaleJson[status]?)

in
    Resultat
