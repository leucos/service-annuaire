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
  `id` CHAR(16) NOT NULL COMMENT 'Identifiant utilisé pour toutes les applications de l\'ent. Son format est définit dans le chaier des charges de l\'annuaire ENT p 43.' ,
  `id_sconet` INT NULL COMMENT 'Identifiant sconet pour les élèves.\nCorrespond à @ENTEleveStructRattachId' ,
  `id_jointure_aaf` INT NULL COMMENT 'identifiant de jointure envoyé par l\'annuaire académique fédérateur' ,
  `login` VARCHAR(45) NULL COMMENT 'Login de l\'utilsateur normalement généré selon le principe première lettre du prenom + nom ou prenom+nom.' ,
  `password` CHAR(60) NULL COMMENT 'BCrypt hashed password' ,
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
  `date_last_maj_aaf` DATETIME NULL ,
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
  `user_id` CHAR(16) NOT NULL ,
  `regroupement_id` INT NOT NULL ,
  `matiere_enseignee_id` INT NOT NULL ,
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
  `user_id` CHAR(16) NOT NULL COMMENT 'Personne en relation avec l\'élève.' ,
  `eleve_id` CHAR(16) NOT NULL COMMENT 'Eleve avec lequel la personne est en relation.' ,
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
  `id` INT NOT NULL AUTO_INCREMENT ,
  `numero` CHAR(32) NOT NULL ,
  `user_id` CHAR(8) NOT NULL ,
  `type_telephone_id` CHAR(4) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_telephone_type_telephone1` (`type_telephone_id` ASC) ,
  INDEX `fk_telephone_user1` (`user_id` ASC) ,
  CONSTRAINT `fk_telephone_type_telephone1`
    FOREIGN KEY (`type_telephone_id` )
    REFERENCES `annuaire`.`type_telephone` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_telephone_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`service`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`service` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`service` (
  `id` CHAR(8) NOT NULL ,
  `libelle` VARCHAR(255) NULL ,
  `description` VARCHAR(1024) NULL ,
  `url` VARCHAR(1024) NULL ,
  `api` TINYINT(1)  NOT NULL COMMENT 'est-ce une api ou une application ?' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`role`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`role` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`role` (
  `id` CHAR(8) NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  `service_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_role_service1` (`service_id` ASC) ,
  CONSTRAINT `fk_role_service1`
    FOREIGN KEY (`service_id` )
    REFERENCES `annuaire`.`service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'Un rôle est lié a une application, son libellé permet de com' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`profil`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`profil` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`profil` (
  `id` CHAR(4) NOT NULL COMMENT 'Identifiant à 4 caractère maximum.\n=code_men si code_men présent' ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(1024) NULL ,
  `code_men` VARCHAR(45) NULL COMMENT 'Code du profil selon le référentiel de l\'éducation nationale.' ,
  `code_national` VARCHAR(45) NULL COMMENT 'Code du profil type National_1.' ,
  `role_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_profil_role1` (`role_id` ASC) ,
  CONSTRAINT `fk_profil_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuaire`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'Il s\'agit du profil général d\'un utilisateur (eleve, parent,' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`activite`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`activite` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`activite` (
  `id` VARCHAR(45) NOT NULL ,
  `libelle` VARCHAR(255) NULL ,
  `description` VARCHAR(1024) NULL ,
  `service_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_activite_service1` (`service_id` ASC) ,
  CONSTRAINT `fk_activite_service1`
    FOREIGN KEY (`service_id` )
    REFERENCES `annuaire`.`service` (`id` )
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
-- Table `annuaire`.`param_service`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`param_service` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`param_service` (
  `id` VARCHAR(45) NOT NULL ,
  `preference` TINYINT(1)  NOT NULL COMMENT 'Preference utilisateur ou param etablissement ?' ,
  `libelle` VARCHAR(255) NULL ,
  `description` VARCHAR(1024) NULL ,
  `valeur_defaut` VARCHAR(2000) NULL ,
  `autres_valeurs` VARCHAR(2000) NULL COMMENT '\'Strings séparée par \\\";\\\". Choix multiples\'' ,
  `service_id` CHAR(8) NOT NULL ,
  `type_param_id` CHAR(4) NOT NULL ,
  `role_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_param_service_type_param1` (`type_param_id` ASC) ,
  INDEX `fk_param_service_service1` (`service_id` ASC) ,
  INDEX `fk_param_service_role1` (`role_id` ASC) ,
  CONSTRAINT `fk_param_service_type_param1`
    FOREIGN KEY (`type_param_id` )
    REFERENCES `annuaire`.`type_param` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_service_service1`
    FOREIGN KEY (`service_id` )
    REFERENCES `annuaire`.`service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_service_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuaire`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'Paramètres de l\'application avec leurs valeurs par défaut. ' ;


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
-- Table `annuaire`.`last_uid`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`last_uid` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`last_uid` (
  `last_uid` CHAR(8) NULL )
ENGINE = InnoDB, 
COMMENT = 'Permet de générer des UID de manière atomique' ;


-- -----------------------------------------------------
-- Table `annuaire`.`email`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`email` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`email` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `adresse` VARCHAR(255) NOT NULL ,
  `principal` TINYINT(1)  NOT NULL DEFAULT 1 COMMENT 'adresse d\'envois par défaut' ,
  `valide` TINYINT(1)  NOT NULL DEFAULT 0 COMMENT 'Si l\'email a été validé suite à un envois de mail (comme GitHub).' ,
  `academique` TINYINT(1)  NOT NULL DEFAULT 0 COMMENT 'Si c\'est un mail académique (pour le PEN)' ,
  `user_id` CHAR(16) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_email_user1` (`user_id` ASC) ,
  CONSTRAINT `fk_email_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`ressource`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`ressource` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`ressource` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `parent_id` INT NULL ,
  `id_externe` VARCHAR(255) NOT NULL ,
  `service_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_ressource_ressource1` (`parent_id` ASC) ,
  INDEX `fk_ressource_service1` (`service_id` ASC) ,
  CONSTRAINT `fk_ressource_ressource1`
    FOREIGN KEY (`parent_id` )
    REFERENCES `annuaire`.`ressource` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_ressource_service1`
    FOREIGN KEY (`service_id` )
    REFERENCES `annuaire`.`service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB, 
COMMENT = 'Une ressource est n\'importe quel élément sur lequel on peut ' /* comment truncated */ ;


-- -----------------------------------------------------
-- Table `annuaire`.`role_user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`role_user` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`role_user` (
  `user_id` CHAR(16) NOT NULL ,
  `ressource_id` INT NOT NULL ,
  `role_id` CHAR(8) NOT NULL ,
  `bloque` TINYINT(1)  NOT NULL DEFAULT 0 ,
  `actif` TINYINT(1)  NULL DEFAULT 1 COMMENT 'le role est-il actif ? utile pour les roles d\'etablissements.' ,
  PRIMARY KEY (`user_id`, `ressource_id`, `role_id`) ,
  INDEX `fk_user_has_ressource_ressource1` (`ressource_id` ASC) ,
  INDEX `fk_user_has_ressource_user1` (`user_id` ASC) ,
  INDEX `fk_role_user_role1` (`role_id` ASC) ,
  CONSTRAINT `fk_user_has_ressource_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_has_ressource_ressource1`
    FOREIGN KEY (`ressource_id` )
    REFERENCES `annuaire`.`ressource` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_role_user_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuaire`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`service_actif`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`service_actif` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`service_actif` (
  `service_id` CHAR(8) NOT NULL ,
  `etablissement_id` INT NOT NULL ,
  `actif` TINYINT(1)  NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`service_id`, `etablissement_id`) ,
  INDEX `fk_service_has_etablissement_etablissement1` (`etablissement_id` ASC) ,
  INDEX `fk_service_has_etablissement_service1` (`service_id` ASC) ,
  CONSTRAINT `fk_service_has_etablissement_service1`
    FOREIGN KEY (`service_id` )
    REFERENCES `annuaire`.`service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_service_has_etablissement_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuaire`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`param_etablissement`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`param_etablissement` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`param_etablissement` (
  `param_service_id` VARCHAR(45) NOT NULL ,
  `etablissement_id` INT NOT NULL ,
  `valeur` VARCHAR(2000) NULL ,
  PRIMARY KEY (`param_service_id`, `etablissement_id`) ,
  INDEX `fk_param_service_has_etablissement_etablissement1` (`etablissement_id` ASC) ,
  INDEX `fk_param_etablissement_param_service1` (`param_service_id` ASC) ,
  CONSTRAINT `fk_param_service_has_etablissement_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuaire`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_etablissement_param_service1`
    FOREIGN KEY (`param_service_id` )
    REFERENCES `annuaire`.`param_service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`param_user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`param_user` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`param_user` (
  `param_service_id` VARCHAR(45) NOT NULL ,
  `user_id` CHAR(16) NOT NULL ,
  `valeur` VARCHAR(2000) NULL ,
  PRIMARY KEY (`param_service_id`, `user_id`) ,
  INDEX `fk_param_service_has_user_user1` (`user_id` ASC) ,
  INDEX `fk_param_user_param_service1` (`param_service_id` ASC) ,
  CONSTRAINT `fk_param_service_has_user_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuaire`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_user_param_service1`
    FOREIGN KEY (`param_service_id` )
    REFERENCES `annuaire`.`param_service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuaire`.`activite_role`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `annuaire`.`activite_role` ;

CREATE  TABLE IF NOT EXISTS `annuaire`.`activite_role` (
  `activite_id` VARCHAR(45) NOT NULL ,
  `role_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`activite_id`, `role_id`) ,
  INDEX `fk_activite_has_role_role1` (`role_id` ASC) ,
  INDEX `fk_activite_has_role_activite1` (`activite_id` ASC) ,
  CONSTRAINT `fk_activite_has_role_activite1`
    FOREIGN KEY (`activite_id` )
    REFERENCES `annuaire`.`activite` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_activite_has_role_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuaire`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
