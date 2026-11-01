-- Revenir à une version précédente du carnet (en cas d'erreur de saisie).
-- 1) Voir les dernières versions :
select id, version, modifie_le, modifie_par from public.carnet_historique order by id desc limit 20;

-- 2) Restaurer celle choisie (remplacez 123 par l'id voulu), puis rechargez l'application :
-- update public.carnet set data = (select data from public.carnet_historique where id = 123), version = version + 1 where id = 1;
