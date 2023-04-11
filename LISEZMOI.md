# flarte

Une application bureau *flutter* (*Linux* et *Windows*) pour naviguer sur le site https://www.arte.tv

<img src="./screenshots/20230324-flarte-640x.png" />

Il copie simplement l'interface sur site, mais ajoute la possibilité de télécharger les vidéos, en utilisant *ffmpeg*.
**Toutes les vidéos sont la propriété d'arte.tv avec droits de reproduction et diffusion réservés.**

Sur Windows, s'attend à trouver le binaire ffmpeg.exe dans le répertoire flarte. Télécharge dans `%USERPROFILE%\Downloads`

Sur Linux, télécharge dans `$XDG_DOWNLOAD_DIR` si défini, et sinon dans `$HOME`

Ceci sera configurable, une fois la fenêtre des "Paramètres" finie.

## Bientot ?

- la fenêtre pour les Paramètres à finir
- des meilleurs controls pour le lecteur intégré
- cast to chromecast
- ajouter france.tv ?

