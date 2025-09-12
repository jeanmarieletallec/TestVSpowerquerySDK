// Script Power Query (M) pour récupérer l'analytical ledger via l'API Pennylane
// Documentation API : https://pennylane.readme.io/reference/getanalyticalgeneralledgerexport

let
    // Paramètre Token à définir dans Power Query
    Token = Parameter("Token"),
    // URL de l'API Pennylane
    url = "https://api.pennylane.com/v1/analyticalGeneralLedgerExport",
    // Requête HTTP avec authentification Bearer
    response = Web.Contents(url,
        [
            Headers = [
                Authorization = "Bearer " & Token,
                Accept = "application/json"
            ]
        ]
    ),
    // Conversion de la réponse en table
    json = Json.Document(response),
    table = Table.FromList(json, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
    // Adapter la transformation selon le format de la réponse
in
    table