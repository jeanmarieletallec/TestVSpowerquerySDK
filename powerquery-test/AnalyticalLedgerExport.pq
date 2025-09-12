// Requête Maîtresse : effectue tout le processus de A à Z
let
    // --- PARAMÈTRES RÉELS ---
    Token = Parameter("Token"), // API Key Pennylane
    CompanyId = Parameter("CompanyId"), // Firm ID
    StartDate = Parameter("StartDate"), // Format : "YYYY-MM-DD"
    EndDate = Parameter("EndDate"), // Format : "YYYY-MM-DD"

    // --- PARTIE 1 : Créer la demande d'export et obtenir l'ID ---
    UrlCreationExport = "https://app.pennylane.com/api/external/v2/exports/analytical_general_ledgers",
    CorpsCreationExport = "{"
        & "\"start_date\": \"" & StartDate & "\"," 
        & "\"end_date\": \"" & EndDate & "\"," 
        & "\"customer_firm_id\": \"" & CompanyId & "\""
        & "}",
    ReponseCreationExport = Json.Document(Web.Contents(UrlCreationExport, [
        Headers = [
            #"Authorization" = "Bearer " & Token,
            #"Content-Type" = "application/json"
        ],
        Content = Text.ToBinary(CorpsCreationExport)
    ])),
    IdExportationObtenu = Text.From(ReponseCreationExport[id]),

    // --- PARTIE 2 : Boucle d'attente (Polling) pour le fichier ---
    UrlStatut = "https://app.pennylane.com/api/external/v2/exports/analytical_general_ledgers/" & IdExportationObtenu,
    EnTetesStatut = [ #"Authorization" = "Bearer " & Token ],
    InterrogerApi = (maxTentatives as number, tentativeActuelle as number) as record =>
        let
            ReponseActuelle = Json.Document(Web.Contents(UrlStatut, [Headers=EnTetesStatut])),
            EstPret = ReponseActuelle[status]? = "ready",
            EstTimeout = tentativeActuelle >= maxTentatives
        in
            if EstPret or EstTimeout then ReponseActuelle
            else let _ = Function.InvokeAfter(()=>null, #duration(0,0,0,10)) in @InterrogerApi(maxTentatives, tentativeActuelle + 1),

    // On attend jusqu'à 5 minutes (30 tentatives * 10 secondes)
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
        error "L'export n'a pas pu être généré dans le temps imparti (5 minutes). Statut final : " & Text.From(ReponseFinaleJson[status]?)
in
    Resultat