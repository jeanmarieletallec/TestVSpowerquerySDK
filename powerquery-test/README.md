# Test de connexion Power Query à l'API Pennylane

Ce dossier contient un exemple de script Power Query (M) permettant de récupérer l'export analytique du grand livre via l'API Pennylane.

## Prérequis
- Un compte Pennylane avec accès développeur
- Un Token généré dans l'interface Pennylane (à renseigner dans Power Query)
- Excel ou Power BI Desktop

## Utilisation
1. Ouvrez Excel ou Power BI Desktop
2. Allez dans l'éditeur Power Query
3. Créez un paramètre nommé `Token` et collez votre token d'API
4. Copiez le contenu du fichier `AnalyticalLedgerExport.pq` dans une nouvelle requête Power Query
5. Exécutez la requête pour récupérer les données

## Script Power Query
Le script utilise la méthode `Web.Contents` pour interroger l'API Pennylane avec le token d'authentification. La réponse JSON est transformée en table.

Pour plus d'informations sur l'API : [Documentation officielle](https://pennylane.readme.io/reference/getanalyticalgeneralledgerexport)

## Personnalisation
- Adaptez la transformation des données selon le format de la réponse JSON
- Ajoutez des paramètres pour filtrer la période ou le type d'export

---
N'hésitez pas à demander si vous souhaitez un exemple plus avancé ou une automatisation supplémentaire.