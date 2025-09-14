// Requête Maîtresse : Version finale validée, avec structure hybride (Body + Query)
let
    // --- PARTIE 0 : Utilisation directe des paramètres ---
    TokenValue = Token,
    CompanyIdValue = Text.From(CompanyId),
    StartDateValue = StartDate,
    EndDateValue = EndDate,

    // --- PARTIE 1 : Créer la demande d'export et obtenir l'ID ---
    UrlCreationExport = "https://app.pennylane.com/api/external/v2/exports/analytical_general_ledgers",
    
    // Les dates vont dans le corps (Body/Content)
    CorpsRecord = [
        period_start = StartDateValue,
        period_end = EndDateValue
    ],
    // Power Query génère un JSON valide, sans virgule en trop.
    CorpsEnJson = Json.FromValue(CorpsRecord),

    // L'ID de l'entreprise va dans l'URL (Query)
    QueryRecord = [
        customer_firm_id = CompanyIdValue
    ],

    ReponseCreationExport = Json.Document(Web.Contents(UrlCreationExport, [
        Headers = [
            #"Authorization" = "Bearer " & TokenValue,
            #"Content-Type" = "application/json"
        ],
        // Paramètres pour l'URL
        Query = QueryRecord,
        // Paramètres pour le corps de la requête
        Content = CorpsEnJson
    ])),
    IdExportationObtenu = Text.From(ReponseCreationExport[id]),

    // --- PARTIE 2 : Boucle d'attente (Polling) pour le fichier ---
    // Il est probable que la requête de statut nécessite aussi l'ID de l'entreprise.
    // Ajoutons-le par sécurité.
    UrlStatut = "https://app.pennylane.com/api/external/v2/exports/analytical_general_ledgers/" & IdExportationObtenu,
    EnTetesStatut = [ #"Authorization" = "Bearer " & TokenValue ],
    QueryStatut = [ #"customer_firm_id" = CompanyIdValue ],

    InterrogerApi = (maxTentatives as number, tentativeActuelle as number) as record => (
        let
            // On ajoute les paramètres à la requête de statut
            ReponseActuelle = Json.Document(Web.Contents(UrlStatut, [Headers=EnTetesStatut, Query=QueryStatut])),
            EstPret = ReponseActuelle[status]? = "ready",
            EstTimeout = tentativeActuelle >= maxTentatives
        in
            if EstPret or EstTimeout then
                ReponseActuelle
            else
                let
                    _ = Function.InvokeAfter(()=>"attente", #duration(0,0,0,10))
                in
                    @InterrogerApi(maxTentatives, tentativeActuelle + 1)
    ),
    ReponseFinaleJson = InterrogerApi(30, 0),

    // --- PARTIE 3 : Téléchargement et traitement du fichier final ---
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
        error "L'export n'a pas pu être généré dans le temps imparti. Statut final : " & Text.From(ReponseFinaleJson[status]?)

in
    Resultat
