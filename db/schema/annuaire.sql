SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

CREATE SCHEMA IF NOT EXISTS `annuaire` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ;
USE `annuaire` ;

-- -----------------------------------------------------
-- Table `annuaire`.`user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`user` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`user` (
  `id` CHAR(8) NOT NULL COMMENT 'Identifiant utilisé pour toutes les applications de l\'ent. Son format est définit dans le chaier des charges de l\'annuaire ENT p 43.' ,
  `vecteur_id` VARCHAR(500) NULL COMMENT 'Est sous la forme \nprofil|nom|prenom|id|etabId\ndonc doit au moins être au moins être aussi long que le nom + prenom + etbId' ,
  `login` VARCHAR(45) NOT NULL COMMENT 'Login de l\'utilsateur normalement généré selon le principe première lettre du prenom + nom ou prenom+nom.' ,
  `password` CHAR(60) NOT NULL COMMENT 'BCrypt hashed password' ,
  `nom` VARCHAR(45) NOT NULL ,
  `prenom` VARCHAR(45) NOT NULL ,
  `sexe` VARCHAR(1) NULL COMMENT 'M ou F' ,
  `question_secrete` VARCHAR(512) NULL ,
  `reponse_question_secrete` CHAR(32) NULL COMMENT 'Réponse à la question secrète. Encodé en MD5 comme un password.' ,
  `date_naissance` DATE NULL ,
  `adresse` VARCHAR(255) NULL ,
  `code_postal` CHAR(6) NULL ,
  `ville` VARCHAR(255) NULL ,
  `date_creation` DATETIME NOT NULL ,
  `date_debut_activation` DATE NULL COMMENT 'Un compte peut avoir une date d\'activation avant laquelle il n\'est pas possible d\'accéder aux infos du compte.' ,
  `date_fin_activation` DATE NULL COMMENT 'La désactivation d\'un compte peut-être prévue (ie compte d\'inspecteur académique)' ,
  `date_derniere_connexion` DATETIME NULL ,
  `bloque` TINYINT(1)  NOT NULL DEFAULT 0 COMMENT 'Si oui ou non le compte est bloqué (plus d\'accès à l\'établissement et autre).' ,
  `id_sconet` INT NULL COMMENT 'Identifiant sconet pour les élèves.\nCorrespond à @ENTEleveStructRattachId' ,
  `id_jointure_aaf` INT NULL COMMENT 'identifiant de jointure envoyé par l\'annuaire académique fédérateur' ,
  `date_last_maj_aaf` DATETIME NULL ,
  `email_principal` VARCHAR(255) NULL ,
  `email_secondaire` VARCHAR(255) NULL ,
  `email_academique` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) ,
  UNIQUE INDEX `id_jointure_aaf_UNIQUE` (`id_jointure_aaf` ASC) ,
  UNIQUE INDEX `id_sconet_UNIQUE` (`id_sconet` ASC) ,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC) ,
  UNIQUE INDEX `login_UNIQUE` (`login` ASC) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`niveau`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`niveau` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`niveau` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  `annee` INT NULL COMMENT 'ordre d\'affichage. Plus on s\'approche de la terminale et plus ce nombre est grand.' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB, 
COMMENT = 'Spécifique regroupement de type classe correspondent à CM2, ' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`type_etablissement`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`type_etablissement` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`type_etablissement` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `nom` VARCHAR(255) NULL ,
  `type_contrat` VARCHAR(10) NULL ,
  `libelle` VARCHAR(255) NULL COMMENT 'Libellé d\'affichage issu des 2 champs type_etab et type_contrat.' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB, 
COMMENT = 'Les données de cette table doivent correspondre aux données ' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`etablissement`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`etablissement` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`etablissement` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `code_uai` CHAR(8) NULL COMMENT 'Code UAI (UNITE ADMINISTRATIVE IMMATRICULEE) de l\'établissement.\nOn peut les trouver ici :\nhttp://www.infocentre.education.fr/ibce/' ,
  `nom` VARCHAR(255) NULL ,
  `siren` VARCHAR(45) NULL ,
  `adresse` VARCHAR(255) NULL ,
  `code_postal` CHAR(6) NULL ,
  `ville` VARCHAR(255) NULL ,
  `telephone` VARCHAR(32) NULL ,
  `fax` VARCHAR(32) NULL ,
  `longitude` FLOAT NULL ,
  `latitude` FLOAT NULL ,
  `date_last_maj_aaf` DATETIME NULL ,
  `nom_passerelle` VARCHAR(255) NULL ,
  `ip_pub_passerelle` VARCHAR(45) NULL ,
  `type_etablissement_id` INT NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_etablissement_type_etablissement1` (`type_etablissement_id` ASC) ,
  CONSTRAINT `fk_etablissement_type_etablissement1`
    FOREIGN KEY (`type_etablissement_id` )
    REFERENCES `annuaire`.`type_etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`type_regroupement`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`type_regroupement` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`type_regroupement` (
  `id` CHAR(4) NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB, 
COMMENT = 'Type de regroupement : classe, groupe d\'élèves, groupes de t' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`regroupement`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`regroupement` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`regroupement` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `libelle` VARCHAR(45) NULL COMMENT 'Libellé fournit par l\'utilisateur. Est par défault égal au libellé sconet en cas d\'alimentation automatique.' ,
  `code_mef_aaf` INT NULL ,
  `date_last_maj_aaf` DATETIME NULL ,
  `libelle_aaf` CHAR(8) NULL COMMENT 'En cas d\'alimentation automatique, un libelle de 8 caractères.' ,
  `niveau_id` INT NULL ,
  `etablissement_id` INT NOT NULL ,
  `type_regroupement_id` CHAR(4) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_regroupement_niveau1` (`niveau_id` ASC) ,
  INDEX `fk_regroupement_etablissement1` (`etablissement_id` ASC) ,
  INDEX `fk_regroupement_type_regroupement1` (`type_regroupement_id` ASC) ,
  CONSTRAINT `fk_regroupement_niveau1`
    FOREIGN KEY (`niveau_id` )
    REFERENCES `annuaire`.`niveau` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_regroupement_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuaire`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_regroupement_type_regroupement1`
    FOREIGN KEY (`type_regroupement_id` )
    REFERENCES `annuaire`.`type_regroupement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`famille_matiere`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`famille_matiere` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`famille_matiere` (
  `id` INT NOT NULL COMMENT 'identifiant de la matière de la table N_FAMILLE_MATIERE de la base commune des nomenclature' ,
  `libelle_court` VARCHAR(45) NULL COMMENT 'libellé court de la matière de la table N_FAMILLE_MATIERE de la base commune des nomenclature' ,
  `libelle_long` VARCHAR(255) NULL COMMENT 'libellé long de la matière de la table N_FAMILLE_MATIERE de la base commune des nomenclature' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB, 
COMMENT = 'Tout les types de matières issus de l\'infocentre de l\'éducat' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`matiere_enseignee`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`matiere_enseignee` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`matiere_enseignee` (
  `id` INT NOT NULL COMMENT 'si commence 9999 alors pas BCN' ,
  `libelle_court` VARCHAR(45) NULL ,
  `libelle_long` VARCHAR(255) NULL ,
  `libelle_edition` VARCHAR(255) NULL ,
  `famille_matiere_id` INT NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_matiere_enseignee_famille_matiere1` (`famille_matiere_id` ASC) ,
  CONSTRAINT `fk_matiere_enseignee_famille_matiere1`
    FOREIGN KEY (`famille_matiere_id` )
    REFERENCES `annuaire`.`famille_matiere` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`enseigne_regroupement`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`enseigne_regroupement` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`enseigne_regroupement` (
  `user_id` CHAR(8) NOT NULL ,
  `regroupement_id` INT NOT NULL ,
  `matiere_enseignee_id` INT NOT NULL ,
  `prof_principal` TINYINT(1)  NULL DEFAULT FALSE ,
  PRIMARY KEY (`user_id`, `regroupement_id`, `matiere_enseignee_id`) ,
  INDEX `fk_user_has_regroupement_regroupement1` (`regroupement_id` ASC) ,
  INDEX `fk_user_has_regroupement_user1` (`user_id` ASC) ,
  INDEX `fk_enseigne_regroupement_matiere_enseignee1` (`matiere_enseignee_id` ASC) ,
  CONSTRAINT `fk_user_has_regroupement_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_has_regroupement_regroupement1`
    FOREIGN KEY (`regroupement_id` )
    REFERENCES `annuaire`.`regroupement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_enseigne_regroupement_matiere_enseignee1`
    FOREIGN KEY (`matiere_enseignee_id` )
    REFERENCES `annuaire`.`matiere_enseignee` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Table spécifique aux Professeur' ;


-- -----------------------------------------------------
-- Table `annuaire`.`membre_regroupement`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`membre_regroupement` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`membre_regroupement` (
  `user_id` CHAR(8) NOT NULL ,
  `regroupement_id` INT NOT NULL ,
  `admin` TINYINT(1)  NULL COMMENT 'groupe libre uniquement' ,
  PRIMARY KEY (`user_id`, `regroupement_id`) ,
  INDEX `fk_user_has_regroupement_regroupement2` (`regroupement_id` ASC) ,
  INDEX `fk_user_has_regroupement_user2` (`user_id` ASC) ,
  CONSTRAINT `fk_user_has_regroupement_user2`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_has_regroupement_regroupement2`
    FOREIGN KEY (`regroupement_id` )
    REFERENCES `annuaire`.`regroupement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`type_relation_eleve`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`type_relation_eleve` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`type_relation_eleve` (
  `id` CHAR(4) NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB, 
COMMENT = 'Type de relation avec les élèves : parent, responsable légal' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`relation_eleve`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`relation_eleve` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`relation_eleve` (
  `user_id` CHAR(8) NOT NULL COMMENT 'Personne en relation avec l\'élève.' ,
  `eleve_id` CHAR(8) NOT NULL COMMENT 'Eleve avec lequel la personne est en relation.' ,
  `type_relation_eleve_id` CHAR(4) NOT NULL ,
  PRIMARY KEY (`user_id`, `eleve_id`) ,
  INDEX `fk_user_has_user_user2` (`user_id` ASC) ,
  INDEX `fk_user_has_user_user1` (`eleve_id` ASC) ,
  INDEX `fk_relation_eleve_type_relation_eleve1` (`type_relation_eleve_id` ASC) ,
  CONSTRAINT `fk_user_has_user_user1`
    FOREIGN KEY (`eleve_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_has_user_user2`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_relation_eleve_type_relation_eleve1`
    FOREIGN KEY (`type_relation_eleve_id` )
    REFERENCES `annuaire`.`type_relation_eleve` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`type_telephone`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`type_telephone` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`type_telephone` (
  `id` CHAR(4) NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`telephone`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`telephone` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`telephone` (
  `numero` CHAR(32) NOT NULL ,
  `user_id` CHAR(8) NOT NULL ,
  `type_telephone_id` CHAR(4) NOT NULL ,
  PRIMARY KEY (`numero`, `user_id`) ,
  INDEX `fk_numero_telephone_user1` (`user_id` ASC) ,
  INDEX `fk_telephone_type_telephone1` (`type_telephone_id` ASC) ,
  CONSTRAINT `fk_numero_telephone_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_telephone_type_telephone1`
    FOREIGN KEY (`type_telephone_id` )
    REFERENCES `annuaire`.`type_telephone` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`profil`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`profil` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`profil` (
  `id` CHAR(4) NOT NULL COMMENT 'Identifiant à 4 caractère maximum.\n=code_men si code_men présent' ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(1024) NULL ,
  `code_men` VARCHAR(45) NULL COMMENT 'Code du profil selon le référentiel de l\'éducation nationale.' ,
  `code_ent` VARCHAR(45) NULL COMMENT 'Code du profil type National_1.' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB, 
COMMENT = 'Il s\'agit du profil général d\'un utilisateur (eleve, parent,' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`profil_user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`profil_user` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`profil_user` (
  `user_id` CHAR(8) NOT NULL ,
  `etablissement_id` INT NOT NULL ,
  `profil_id` CHAR(4) NOT NULL ,
  `bloque` TINYINT(1)  NULL ,
  `actif` TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '1seul profil actif par user' ,
  PRIMARY KEY (`user_id`, `etablissement_id`, `profil_id`) ,
  INDEX `fk_type_profil_has_user_user1` (`user_id` ASC) ,
  INDEX `fk_profils_utilisateur_etablissement1` (`etablissement_id` ASC) ,
  INDEX `fk_profil_utilisateur_profil1` (`profil_id` ASC) ,
  CONSTRAINT `fk_type_profil_has_user_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_profils_utilisateur_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuaire`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_profil_utilisateur_profil1`
    FOREIGN KEY (`profil_id` )
    REFERENCES `annuaire`.`profil` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'Une personne peut être rattachée à plusieurs établissements ' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`app`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`app` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`app` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `code` VARCHAR(45) NOT NULL ,
  `libelle` VARCHAR(255) NULL ,
  `description` VARCHAR(1024) NULL ,
  `url` VARCHAR(1024) NULL COMMENT 'typiquement une application se trouve a une url précise qui permettra d\'y accéder via le web.\nEg /trombinoscope' ,
  PRIMARY KEY (`id`) ,
  UNIQUE INDEX `code_UNIQUE` (`code` ASC) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`app_active`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`app_active` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`app_active` (
  `application_id` INT NOT NULL ,
  `etablissement_id` INT NOT NULL ,
  `active` TINYINT(1)  NULL ,
  PRIMARY KEY (`application_id`, `etablissement_id`) ,
  INDEX `fk_application_has_etablissement_application1` (`application_id` ASC) ,
  INDEX `fk_app_active_etablissement1` (`etablissement_id` ASC) ,
  CONSTRAINT `fk_application_has_etablissement_application1`
    FOREIGN KEY (`application_id` )
    REFERENCES `annuaire`.`app` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_app_active_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuaire`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'Chaque établissement peut choisir s\'il active ou non une app' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`activite`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`activite` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`activite` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `code` VARCHAR(45) NOT NULL COMMENT 'ne doit pas comporter d\'espace.' ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(1024) NULL ,
  `app_id` INT NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_role_applicatif_app1` (`app_id` ASC) ,
  CONSTRAINT `fk_role_applicatif_app1`
    FOREIGN KEY (`app_id` )
    REFERENCES `annuaire`.`app` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'ensemble des roles d\'une application\n' ;


-- -----------------------------------------------------
-- Table `annuaire`.`type_param`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`type_param` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`type_param` (
  `id` CHAR(4) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`role`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`role` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`role` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  `app_id` INT NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_role_app1` (`app_id` ASC) ,
  CONSTRAINT `fk_role_app1`
    FOREIGN KEY (`app_id` )
    REFERENCES `annuaire`.`app` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'Un rôle est lié a une application, son libellé permet de com' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`param_app`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`param_app` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`param_app` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `code` VARCHAR(45) NOT NULL ,
  `preference` TINYINT(1)  NOT NULL COMMENT 'Preference utilisateur ou param etablissement ?' ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  `valeur_defaut` VARCHAR(2000) NULL ,
  `autres_valeurs` VARCHAR(2000) NULL COMMENT '\'Strings séparée par \\\";\\\". Choix multiples\'' ,
  `app_id` INT NOT NULL ,
  `type_param_id` CHAR(4) NOT NULL ,
  `role_id` INT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_param_app_app1` (`app_id` ASC) ,
  INDEX `fk_param_app_type_param1` (`type_param_id` ASC) ,
  INDEX `fk_param_app_role1` (`role_id` ASC) ,
  CONSTRAINT `fk_param_app_app1`
    FOREIGN KEY (`app_id` )
    REFERENCES `annuaire`.`app` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_app_type_param1`
    FOREIGN KEY (`type_param_id` )
    REFERENCES `annuaire`.`type_param` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_app_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuaire`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'Paramètres de l\'application avec leurs valeurs par défaut. ' ;


-- -----------------------------------------------------
-- Table `annuaire`.`activite_role`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`activite_role` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`activite_role` (
  `activite_id` INT NOT NULL ,
  `role_id` INT NOT NULL ,
  INDEX `fk_activite_role_activite1` (`activite_id` ASC) ,
  INDEX `fk_activite_role_role1` (`role_id` ASC) ,
  PRIMARY KEY (`activite_id`, `role_id`) ,
  CONSTRAINT `fk_activite_role_activite1`
    FOREIGN KEY (`activite_id` )
    REFERENCES `annuaire`.`activite` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_activite_role_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuaire`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`role_profil`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`role_profil` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`role_profil` (
  `role_id` INT NOT NULL ,
  `profil_id` CHAR(4) NOT NULL ,
  PRIMARY KEY (`role_id`, `profil_id`) ,
  INDEX `fk_role_has_profil_profil1` (`profil_id` ASC) ,
  INDEX `fk_role_has_profil_role1` (`role_id` ASC) ,
  CONSTRAINT `fk_role_has_profil_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuaire`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_role_has_profil_profil1`
    FOREIGN KEY (`profil_id` )
    REFERENCES `annuaire`.`profil` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`fonction`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`fonction` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`fonction` (
  `id` INT NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(1024) NULL ,
  `code_men` VARCHAR(45) NULL ,
  `profil_id` CHAR(4) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_fonction_profil1` (`profil_id` ASC) ,
  CONSTRAINT `fk_fonction_profil1`
    FOREIGN KEY (`profil_id` )
    REFERENCES `annuaire`.`profil` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'La fonction est la table \"pour faire plaisir\" :). Il s\'agit ' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`role_user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`role_user` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`role_user` (
  `role_id` INT NOT NULL ,
  `profil_user_user_id` CHAR(8) NOT NULL ,
  `profil_user_etablissement_id` INT NOT NULL ,
  `profil_user_profil_id` CHAR(4) NOT NULL ,
  PRIMARY KEY (`role_id`, `profil_user_user_id`, `profil_user_etablissement_id`, `profil_user_profil_id`) ,
  INDEX `fk_role_has_profil_user_profil_user1` (`profil_user_user_id` ASC, `profil_user_etablissement_id` ASC, `profil_user_profil_id` ASC) ,
  INDEX `fk_role_has_profil_user_role1` (`role_id` ASC) ,
  CONSTRAINT `fk_role_has_profil_user_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuaire`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_role_has_profil_user_profil_user1`
    FOREIGN KEY (`profil_user_user_id` , `profil_user_etablissement_id` , `profil_user_profil_id` )
    REFERENCES `annuaire`.`profil_user` (`user_id` , `etablissement_id` , `profil_id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`param_user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`param_user` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`param_user` (
  `param_app_id` INT NOT NULL ,
  `user_id` CHAR(8) NOT NULL ,
  `valeur` VARCHAR(2000) NULL ,
  PRIMARY KEY (`param_app_id`, `user_id`) ,
  INDEX `fk_param_app_has_user_user1` (`user_id` ASC) ,
  INDEX `fk_param_app_has_user_param_app1` (`param_app_id` ASC) ,
  CONSTRAINT `fk_param_app_has_user_param_app1`
    FOREIGN KEY (`param_app_id` )
    REFERENCES `annuaire`.`param_app` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_app_has_user_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`param_etablissement`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`param_etablissement` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`param_etablissement` (
  `param_app_id` INT NOT NULL ,
  `etablissement_id` INT NOT NULL ,
  `valeur` VARCHAR(2000) NULL ,
  PRIMARY KEY (`param_app_id`, `etablissement_id`) ,
  INDEX `fk_param_app_has_etablissement_etablissement1` (`etablissement_id` ASC) ,
  INDEX `fk_param_app_has_etablissement_param_app1` (`param_app_id` ASC) ,
  CONSTRAINT `fk_param_app_has_etablissement_param_app1`
    FOREIGN KEY (`param_app_id` )
    REFERENCES `annuaire`.`param_app` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_app_has_etablissement_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuaire`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`last_uid`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`last_uid` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`last_uid` (
  `last_uid` CHAR(8) NULL )
ENGINE = InnoDB, 
COMMENT = 'Permet de générer des UID de manière atomique' ;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
