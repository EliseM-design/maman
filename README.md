# Maison & Patrimoine

Carnet privé de gestion du patrimoine familial : biens, loyers, dépenses (sur un ou plusieurs biens), prêts, travaux, documents, fiscalité et décisions futures.

- **Hébergement** : Vercel (site statique, sans serveur à maintenir)
- **Données, connexion et fichiers** : Supabase (base Postgres, connexion par lien e-mail, stockage privé des justificatifs)
- **Accès** : seules les adresses e-mail listées dans la table `membres` peuvent ouvrir le carnet

## Mise en ligne (environ 15 minutes, une seule fois)

### 1. Supabase : créer la base
1. Créez un compte sur [supabase.com](https://supabase.com), puis **New project**. Choisissez la région **Europe (Paris ou Frankfurt)** et notez le mot de passe de la base.
2. Ouvrez **SQL Editor > New query**, collez tout le contenu de `supabase/schema.sql`.
3. **Avant de cliquer sur Run**, remplacez à la fin `votre-adresse@exemple.fr` par votre adresse e-mail. Ajoutez celles des autres membres de la famille sur le même modèle.
4. Cliquez sur **Run**. Le message « Success. No rows returned » est normal.

### 2. GitHub : déposer le code
1. Sur [github.com/new](https://github.com/new), créez un dépôt **privé** nommé `maison-patrimoine`, sans README.
2. Dans ce dossier, sur votre ordinateur :
   ```bash
   git remote add origin https://github.com/VOTRE-COMPTE/maison-patrimoine.git
   git push -u origin main
   ```
   Sans ligne de commande : sur la page du dépôt vide, cliquez sur **uploading an existing file** et glissez le contenu du dossier, sans `node_modules` ni `dist`.

### 3. Vercel : publier le site
1. Sur [vercel.com/new](https://vercel.com/new), connectez-vous avec GitHub et **importez** le dépôt `maison-patrimoine`.
2. Dans **Environment Variables**, ajoutez :
   - `SUPABASE_URL` : Supabase > Project Settings > API > **Project URL**
   - `SUPABASE_ANON_KEY` : même page, clé **anon / public**. N'utilisez jamais la clé `service_role`.

   Vous pouvez aussi installer l'intégration Supabase de Vercel, qui ajoute ces variables toute seule.
3. Cliquez sur **Deploy**. Vercel vous donne une adresse du type `maison-patrimoine.vercel.app`.

### 4. Supabase : autoriser l'adresse du site
Dans Supabase > **Authentication > URL Configuration** :
- **Site URL** : l'adresse donnée par Vercel, par exemple `https://maison-patrimoine.vercel.app`
- **Redirect URLs** : ajoutez cette même adresse.

Sans cette étape, le lien de connexion reçu par e-mail ne ramène pas sur le carnet.

### 5. Première connexion
Ouvrez le site, saisissez votre e-mail et cliquez sur le lien reçu. Au premier passage, le carnet est créé avec les **données d'exemple**. Effacez-les depuis **Plus > Mes données > Effacer l'exemple**.

## Ajouter un membre de la famille
Supabase > **Table Editor > membres > Insert row** : saisissez son adresse e-mail. Elle peut ensuite se connecter avec son propre lien.

## Sécurité et sauvegardes
- Toutes les tables sont protégées : une personne qui n'est pas dans `membres` ne voit rien, même connectée.
- Les justificatifs sont dans un espace de stockage **privé**. Les liens d'ouverture expirent au bout d'une heure.
- Chaque modification garde la version précédente dans `carnet_historique` (500 dernières versions). Pour revenir en arrière, utilisez `supabase/restaurer-une-version.sql`.
- Les e-mails de connexion de Supabase sont limités à quelques envois par heure. Pour une famille, c'est suffisant. Au-delà, branchez un service d'envoi dans Authentication > SMTP Settings.

## Modifier l'application
Tout le code de l'interface est dans `src/app.html`. Le script `scripts/build.mjs` y ajoute la configuration Supabase au moment de la publication. Chaque `git push` sur `main` republie automatiquement le site sur Vercel.

Pour tester en local :
```bash
cp .env.example .env   # puis remplissez les deux valeurs
npm install
npm run dev            # http://localhost:3000
```
Sans fichier `.env`, l'application tourne en mode local : les données restent dans le navigateur.
