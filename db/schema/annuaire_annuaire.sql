SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

DROP SCHEMA IF EXISTS `annuairev3` ;
CREATE SCHEMA IF NOT EXISTS `annuairev3` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ;
USE `annuairev3` ;

-- -----------------------------------------------------
-- Table `annuairev3`.`user`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`user` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT 'Identifiant utilisé pour toutes les applications de l\'ent. Son format est définit dans le chaier des charges de l\'annuaire ENT p 43.' ,
  `id_sconet` INT NULL COMMENT 'Identifiant sconet pour les élèves.\nCorrespond à @ENTEleveStructRattachId' ,
  `id_jointure_aaf` INT NULL COMMENT 'identifiant de jointure envoyé par l\'annuaire académique fédérateur' ,
  `login` VARCHAR(45) NULL COMMENT 'Login de l\'utilsateur normalement généré selon le principe première lettre du prenom + nom ou prenom+nom.' ,
  `password` CHAR(60) NULL COMMENT 'BCrypt hashed password' ,
  `nom` VARCHAR(45) NOT NULL ,
  `prenom` VARCHAR(45) NOT NULL ,
  `sexe` VARCHAR(1) NULL COMMENT 'M ou F' ,
  `date_naissance` DATE NULL ,
  `adresse` VARCHAR(255) NULL ,
  `code_postal` CHAR(6) NULL ,
  `ville` VARCHAR(255) NULL ,
  `date_creation` DATE NOT NULL ,
  `date_debut_activation` DATE NULL COMMENT 'Un compte peut avoir une date d\'activation avant laquelle il n\'est pas possible d\'accéder aux infos du compte.' ,
  `date_fin_activation` DATE NULL COMMENT 'La désactivation d\'un compte peut-être prévue (ie compte d\'inspecteur académique)' ,
  `date_derniere_connexion` DATETIME NULL ,
  `bloque` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si oui ou non le compte est bloqué (plus d\'accès à l\'établissement et autre).' ,
  `change_password` TINYINT(1) NULL DEFAULT 0 COMMENT 'doit changer son password' ,
  `id_ent` CHAR(16) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `id_jointure_aaf_UNIQUE` USING BTREE (`id_jointure_aaf` ASC) ,
  UNIQUE INDEX `id_sconet_UNIQUE` (`id_sconet` ASC) ,
  UNIQUE INDEX `login_UNIQUE` (`login` ASC) ,
  UNIQUE INDEX `id_ent_UNIQUE` (`id_ent` ASC) )
ENGINE = InnoDB
COMMENT = 'change id to integer and \nmodify id_ent';


-- -----------------------------------------------------
-- Table `annuairev3`.`type_regroupement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`type_regroupement` (
  `id` CHAR(8) NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'Type de regroupement : classe, groupe d\'élèves, groupes de t' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`niveau`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`niveau` (
  `ent_mef_jointure` VARCHAR(20) NOT NULL ,
  `mef_libelle` VARCHAR(256) NULL ,
  `ent_mef_rattach` VARCHAR(20) NULL ,
  `ent_mef_stat` VARCHAR(20) NULL ,
  PRIMARY KEY (`ent_mef_jointure`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`type_etablissement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`type_etablissement` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `nom` VARCHAR(255) NULL ,
  `type_contrat` VARCHAR(10) NULL ,
  `libelle` VARCHAR(255) NULL COMMENT 'Libellé d\'affichage issu des 2 champs type_etab et type_contrat.' ,
  `type_struct_aaf` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'Les données de cette table doivent correspondre aux données ' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`etablissement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`etablissement` (
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
  `date_last_maj_aaf` DATE NULL ,
  `nom_passerelle` VARCHAR(255) NULL ,
  `ip_pub_passerelle` VARCHAR(45) NULL ,
  `type_etablissement_id` INT NOT NULL ,
  `alimentation_state` VARCHAR(45) NOT NULL DEFAULT 'Non alimenté' ,
  `alimentation_date` DATE NULL ,
  `data_received` TINYINT(1) NOT NULL DEFAULT 0 ,
  `site_url` VARCHAR(255) NULL ,
  `logo` VARCHAR(45) NULL ,
  `last_alimentation` DATE NULL ,
  `activate_alimentation` TINYINT(1) NULL ,
  INDEX `fk_etablissement_type_etablissement1` (`type_etablissement_id` ASC) ,
  PRIMARY KEY (`id`) ,
  CONSTRAINT `fk_etablissement_type_etablissement1`
    FOREIGN KEY (`type_etablissement_id` )
    REFERENCES `annuairev3`.`type_etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'notes : \nid = structure_jointure \nchange type data_last_maj_' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`regroupement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`regroupement` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `libelle` VARCHAR(45) NULL COMMENT 'Libellé fournit par l\'utilisateur. Est par défault égal au libellé sconet en cas d\'alimentation automatique.' ,
  `description` TEXT NULL ,
  `date_last_maj_aaf` DATE NULL ,
  `libelle_aaf` CHAR(8) NULL COMMENT 'En cas d\'alimentation automatique, un libelle de 8 caractères.' ,
  `type_regroupement_id` CHAR(8) NOT NULL ,
  `code_mef_aaf` VARCHAR(20) NULL ,
  `etablissement_id` INT NOT NULL ,
  `date_creation` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_regroupement_type_regroupement1` (`type_regroupement_id` ASC) ,
  INDEX `fk_regroupement_niveau1` (`code_mef_aaf` ASC) ,
  INDEX `fk_regroupement_etablissement1` (`etablissement_id` ASC) ,
  CONSTRAINT `fk_regroupement_type_regroupement1`
    FOREIGN KEY (`type_regroupement_id` )
    REFERENCES `annuairev3`.`type_regroupement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_regroupement_niveau1`
    FOREIGN KEY (`code_mef_aaf` )
    REFERENCES `annuairev3`.`niveau` (`ent_mef_jointure` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_regroupement_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuairev3`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'change code_mef to code_mef_aaf ';


-- -----------------------------------------------------
-- Table `annuairev3`.`matiere_enseignee`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`matiere_enseignee` (
  `id` VARCHAR(10) NOT NULL COMMENT 'si commence 9999 alors pas BCN' ,
  `libelle_court` VARCHAR(45) NULL ,
  `libelle_long` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`enseigne_dans_regroupement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`enseigne_dans_regroupement` (
  `user_id` INT NOT NULL ,
  `regroupement_id` INT NOT NULL ,
  `matiere_enseignee_id` VARCHAR(10) NOT NULL ,
  `prof_principal` VARCHAR(45) NOT NULL DEFAULT 'N' ,
  INDEX `fk_user_has_regroupement_regroupement1` (`regroupement_id` ASC) ,
  INDEX `fk_user_has_regroupement_user1` (`user_id` ASC) ,
  INDEX `fk_enseigne_regroupement_matiere_enseignee1` (`matiere_enseignee_id` ASC) ,
  PRIMARY KEY (`regroupement_id`, `user_id`, `matiere_enseignee_id`) ,
  CONSTRAINT `fk_user_has_regroupement_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_has_regroupement_regroupement1`
    FOREIGN KEY (`regroupement_id` )
    REFERENCES `annuairev3`.`regroupement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_enseigne_regroupement_matiere_enseignee1`
    FOREIGN KEY (`matiere_enseignee_id` )
    REFERENCES `annuairev3`.`matiere_enseignee` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Table spécifique aux Professeur';


-- -----------------------------------------------------
-- Table `annuairev3`.`type_relation_eleve`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`type_relation_eleve` (
  `id` TINYINT(2) NOT NULL ,
  `description` VARCHAR(45) NULL ,
  `libelle` VARCHAR(10) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'Type de relation avec les élèves : parent, responsable légal' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`relation_eleve`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`relation_eleve` (
  `user_id` INT NOT NULL COMMENT 'Personne en relation avec l\'élève.' ,
  `eleve_id` INT NOT NULL COMMENT 'Eleve avec lequel la personne est en relation.' ,
  `type_relation_eleve_id` TINYINT(2) NOT NULL ,
  `resp_financier` TINYINT(1) NULL DEFAULT 0 ,
  `resp_legal` TINYINT(1) NULL DEFAULT 0 ,
  `contact` TINYINT(1) NULL DEFAULT 0 ,
  `paiement` TINYINT(1) NULL DEFAULT 0 ,
  PRIMARY KEY (`user_id`, `eleve_id`, `type_relation_eleve_id`) ,
  INDEX `fk_user_has_user_user2` (`user_id` ASC) ,
  INDEX `fk_user_has_user_user1` (`eleve_id` ASC) ,
  INDEX `fk_relation_eleve_type_relation_eleve1` (`type_relation_eleve_id` ASC) ,
  CONSTRAINT `fk_user_has_user_user1`
    FOREIGN KEY (`eleve_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_has_user_user2`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_relation_eleve_type_relation_eleve1`
    FOREIGN KEY (`type_relation_eleve_id` )
    REFERENCES `annuairev3`.`type_relation_eleve` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`type_telephone`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`type_telephone` (
  `id` CHAR(8) NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`telephone`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`telephone` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `numero` CHAR(32) NOT NULL ,
  `user_id` INT NOT NULL ,
  `type_telephone_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_telephone_user1` (`user_id` ASC) ,
  INDEX `fk_telephone_type_telephone1` (`type_telephone_id` ASC) ,
  CONSTRAINT `fk_telephone_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_telephone_type_telephone1`
    FOREIGN KEY (`type_telephone_id` )
    REFERENCES `annuairev3`.`type_telephone` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`role`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`role` (
  `id` VARCHAR(20) NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(255) NULL ,
  `priority` INT NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'Un rôle est lié a une application, son libellé permet de com' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`profil_national`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`profil_national` (
  `id` CHAR(8) NOT NULL COMMENT 'Identifiant à 4 caractère maximum.\n=code_men si code_men présent' ,
  `description` VARCHAR(100) NULL ,
  `code_national` VARCHAR(45) NULL COMMENT 'Code du profil type National_1.' ,
  `role_id` VARCHAR(20) NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_profil_role1` (`role_id` ASC) ,
  CONSTRAINT `fk_profil_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuairev3`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'profil table is  a reference table that make use of the docu' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`activite`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`activite` (
  `id` VARCHAR(45) NOT NULL ,
  `libelle` VARCHAR(255) NULL ,
  `description` VARCHAR(1024) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'ensemble des roles d\'une application\n';


-- -----------------------------------------------------
-- Table `annuairev3`.`application`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`application` (
  `id` CHAR(8) NOT NULL ,
  `libelle` VARCHAR(255) NULL ,
  `description` VARCHAR(500) NULL ,
  `url` VARCHAR(45) NOT NULL ,
  `active` TINYINT(1) NULL DEFAULT 1 ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'application:\nLaclasse.com\ngestion Etablissement\ngestion user' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`type_param`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`type_param` (
  `id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'url\ninterne /externe \npriorite \nfonts\n...';


-- -----------------------------------------------------
-- Table `annuairev3`.`param_application`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`param_application` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `code` VARCHAR(45) NOT NULL ,
  `preference` TINYINT(1) NOT NULL COMMENT 'Preference utilisateur ou param etablissement ?' ,
  `visible` TINYINT(1) NOT NULL DEFAULT 1 ,
  `libelle` VARCHAR(255) NULL ,
  `description` VARCHAR(1024) NULL ,
  `valeur_defaut` VARCHAR(2000) NULL ,
  `autres_valeurs` VARCHAR(2000) NULL COMMENT '\'Strings séparée par \\\";\\\". Choix multiples\'' ,
  `application_id` CHAR(8) NOT NULL ,
  `type_param_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_param_application_application1` (`application_id` ASC) ,
  INDEX `fk_param_application_type_param1` (`type_param_id` ASC) ,
  CONSTRAINT `fk_param_application_application1`
    FOREIGN KEY (`application_id` )
    REFERENCES `annuairev3`.`application` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_application_type_param1`
    FOREIGN KEY (`type_param_id` )
    REFERENCES `annuairev3`.`type_param` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Paramètres de l\'application avec leurs valeurs par défaut. ';


-- -----------------------------------------------------
-- Table `annuairev3`.`fonction`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`fonction` (
  `libelle` VARCHAR(45) NULL ,
  `description` VARCHAR(100) NULL ,
  `code_men` VARCHAR(20) NULL ,
  `id` INT NOT NULL AUTO_INCREMENT ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'fonction is a reference table de reference alimented by the ' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`last_uid`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`last_uid` (
  `last_uid` CHAR(8) NULL )
ENGINE = InnoDB
COMMENT = 'Permet de générer des UID de manière atomique';


-- -----------------------------------------------------
-- Table `annuairev3`.`email`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`email` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `adresse` VARCHAR(255) NOT NULL ,
  `principal` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'adresse d\'envois par défaut' ,
  `valide` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si l\'email a été validé suite à un envois de mail (comme GitHub).' ,
  `academique` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si c\'est un mail académique (pour le PEN)' ,
  `user_id` INT NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_email_user1` (`user_id` ASC) ,
  CONSTRAINT `fk_email_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`service`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`service` (
  `id` CHAR(8) NOT NULL ,
  `libelle` VARCHAR(255) NULL ,
  `description` VARCHAR(1024) NULL ,
  `url` VARCHAR(1024) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'service or type of resource, or type of subject\n\nnote: is it' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`ressource`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`ressource` (
  `id` VARCHAR(255) NOT NULL ,
  `service_id` CHAR(8) NOT NULL ,
  INDEX `fk_ressource_service1` (`service_id` ASC) ,
  PRIMARY KEY (`service_id`, `id`) ,
  CONSTRAINT `fk_ressource_service1`
    FOREIGN KEY (`service_id` )
    REFERENCES `annuairev3`.`service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Une ressource est n\'importe quel élément sur lequel on peut ' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`param_etablissement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`param_etablissement` (
  `etablissement_id` INT NOT NULL ,
  `param_application_id` INT NOT NULL ,
  `valeur` VARCHAR(2000) NULL ,
  PRIMARY KEY (`etablissement_id`, `param_application_id`) ,
  INDEX `fk_param_application_has_etablissement_etablissement1` (`etablissement_id` ASC) ,
  INDEX `fk_param_etablissement_param_application1` (`param_application_id` ASC) ,
  CONSTRAINT `fk_param_application_has_etablissement_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuairev3`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_etablissement_param_application1`
    FOREIGN KEY (`param_application_id` )
    REFERENCES `annuairev3`.`param_application` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`param_user`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`param_user` (
  `user_id` INT NOT NULL ,
  `param_application_id` INT NOT NULL ,
  `valeur` VARCHAR(2000) NULL ,
  PRIMARY KEY (`user_id`, `param_application_id`) ,
  INDEX `fk_param_application_has_user_user1` (`user_id` ASC) ,
  INDEX `fk_param_user_param_application1` (`param_application_id` ASC) ,
  CONSTRAINT `fk_param_application_has_user_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_param_user_param_application1`
    FOREIGN KEY (`param_application_id` )
    REFERENCES `annuairev3`.`param_application` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`role_user`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`role_user` (
  `user_id` INT NOT NULL ,
  `role_id` VARCHAR(20) NOT NULL ,
  `bloque` TINYINT(1) NOT NULL DEFAULT 0 ,
  `etablissement_id` INT NOT NULL ,
  PRIMARY KEY (`user_id`, `role_id`, `etablissement_id`) ,
  INDEX `fk_role_user_user1` (`user_id` ASC) ,
  INDEX `fk_role_user_role1` (`role_id` ASC) ,
  INDEX `fk_role_user_etablissement1` (`etablissement_id` ASC) ,
  CONSTRAINT `fk_role_has_user_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_role_user_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuairev3`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_role_user_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuairev3`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`profil_user`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`profil_user` (
  `profil_id` CHAR(8) NOT NULL ,
  `user_id` INT NOT NULL ,
  `etablissement_id` INT NOT NULL ,
  PRIMARY KEY (`profil_id`, `user_id`, `etablissement_id`) ,
  INDEX `fk_profil_has_user_user1` (`user_id` ASC) ,
  INDEX `fk_profil_user_etablissement1` (`etablissement_id` ASC) ,
  INDEX `fk_profil_user_profil1` (`profil_id` ASC) ,
  CONSTRAINT `fk_profil_has_user_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_profil_user_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuairev3`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_profil_user_profil1`
    FOREIGN KEY (`profil_id` )
    REFERENCES `annuairev3`.`profil_national` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'profil_user is the table that link  the user to an etablisse' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`application_etablissement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`application_etablissement` (
  `application_id` CHAR(8) NOT NULL ,
  `etablissement_id` INT NOT NULL ,
  `active` TINYINT(1) NULL DEFAULT true ,
  PRIMARY KEY (`application_id`, `etablissement_id`) ,
  INDEX `fk_application_has_etablissement_etablissement1` (`etablissement_id` ASC) ,
  INDEX `fk_application_has_etablissement_application1` (`application_id` ASC) ,
  CONSTRAINT `fk_application_has_etablissement_application1`
    FOREIGN KEY (`application_id` )
    REFERENCES `annuairev3`.`application` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_application_has_etablissement_etablissement1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `annuairev3`.`etablissement` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`eleve_dans_regroupement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`eleve_dans_regroupement` (
  `user_id` INT NOT NULL ,
  `regroupement_id` INT NOT NULL ,
  PRIMARY KEY (`user_id`, `regroupement_id`) ,
  INDEX `fk_user_has_regroupement_regroupement2` (`regroupement_id` ASC) ,
  INDEX `fk_user_has_regroupement_user2` (`user_id` ASC) ,
  CONSTRAINT `fk_user_has_regroupement_user2`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_has_regroupement_regroupement2`
    FOREIGN KEY (`regroupement_id` )
    REFERENCES `annuairev3`.`regroupement` (`id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`profil_user_fonction`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`profil_user_fonction` (
  `profil_id` CHAR(8) NOT NULL ,
  `user_id` INT NOT NULL ,
  `etablissement_id` INT NOT NULL ,
  `fonction_id` INT NOT NULL ,
  PRIMARY KEY (`user_id`, `etablissement_id`, `profil_id`, `fonction_id`) ,
  INDEX `fk_profil_user_has_fonction_profil_user1` (`profil_id` ASC, `user_id` ASC, `etablissement_id` ASC) ,
  INDEX `fk_profil_user_fonction_fonction1` (`fonction_id` ASC) ,
  CONSTRAINT `fk_profil_user_has_fonction_profil_user1`
    FOREIGN KEY (`profil_id` , `user_id` , `etablissement_id` )
    REFERENCES `annuairev3`.`profil_user` (`profil_id` , `user_id` , `etablissement_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_profil_user_fonction_fonction1`
    FOREIGN KEY (`fonction_id` )
    REFERENCES `annuairev3`.`fonction` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'this table generated from many to many between profil_user a' /* comment truncated */;


-- -----------------------------------------------------
-- Table `annuairev3`.`activite_role`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`activite_role` (
  `activite_id` VARCHAR(45) NOT NULL ,
  `role_id` VARCHAR(20) NOT NULL ,
  `service_id` CHAR(8) NOT NULL ,
  `condition` VARCHAR(45) NOT NULL ,
  `parent_service_id` CHAR(8) NOT NULL ,
  PRIMARY KEY (`activite_id`, `role_id`, `service_id`, `parent_service_id`) ,
  INDEX `fk_role_has_service_has_activite_activite1` (`activite_id` ASC) ,
  INDEX `fk_activite_role_role1` (`role_id` ASC) ,
  INDEX `fk_activite_role_service1` (`service_id` ASC) ,
  INDEX `fk_activite_role_service2` (`parent_service_id` ASC) ,
  CONSTRAINT `fk_role_has_service_has_activite_activite1`
    FOREIGN KEY (`activite_id` )
    REFERENCES `annuairev3`.`activite` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_activite_role_role1`
    FOREIGN KEY (`role_id` )
    REFERENCES `annuairev3`.`role` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_activite_role_service1`
    FOREIGN KEY (`service_id` )
    REFERENCES `annuairev3`.`service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_activite_role_service2`
    FOREIGN KEY (`parent_service_id` )
    REFERENCES `annuairev3`.`service` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'condition in activite_role \nare: :all, :self, belongs_to';


-- -----------------------------------------------------
-- Table `annuairev3`.`application_key`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`application_key` (
  `application_id` CHAR(8) NOT NULL ,
  `application_key` VARCHAR(255) NOT NULL ,
  `application_secret` VARCHAR(45) NOT NULL ,
  `created_at` DATETIME NOT NULL ,
  `validity_duration` INT NOT NULL ,
  INDEX `fk_application_key_application1` (`application_id` ASC) ,
  PRIMARY KEY (`application_id`) ,
  CONSTRAINT `fk_application_key_application1`
    FOREIGN KEY (`application_id` )
    REFERENCES `annuairev3`.`application` (`id` )
    ON DELETE CASCADE
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`regroupement_libre`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`regroupement_libre` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `created_at` DATE NULL ,
  `created_by` INT NOT NULL ,
  `libelle` VARCHAR(45) NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_regroupement_libre_user1` (`created_by` ASC) ,
  CONSTRAINT `fk_regroupement_libre_user1`
    FOREIGN KEY (`created_by` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `annuairev3`.`membre_regroupement_libre`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `annuairev3`.`membre_regroupement_libre` (
  `user_id` INT NOT NULL ,
  `regroupement_libre_id` INT NOT NULL ,
  `joined_at` DATE NULL ,
  PRIMARY KEY (`user_id`, `regroupement_libre_id`) ,
  INDEX `fk_user_has_regroupement_libre_regroupement_libre1` (`regroupement_libre_id` ASC) ,
  INDEX `fk_user_has_regroupement_libre_user1` (`user_id` ASC) ,
  CONSTRAINT `fk_user_has_regroupement_libre_user1`
    FOREIGN KEY (`user_id` )
    REFERENCES `annuairev3`.`user` (`id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_user_has_regroupement_libre_regroupement_libre1`
    FOREIGN KEY (`regroupement_libre_id` )
    REFERENCES `annuairev3`.`regroupement_libre` (`id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- -----------------------------------------------------
-- Data for table `annuairev3`.`type_regroupement`
-- -----------------------------------------------------
START TRANSACTION;
USE `annuairev3`;
INSERT INTO `annuairev3`.`type_regroupement` (`id`, `libelle`, `description`) VALUES ('1', 'CLS', 'Classe');
INSERT INTO `annuairev3`.`type_regroupement` (`id`, `libelle`, `description`) VALUES ('2', 'GRP', 'Groupe d\'élèves');
INSERT INTO `annuairev3`.`type_regroupement` (`id`, `libelle`, `description`) VALUES ('3', 'ENV', 'Groupe de travail');

COMMIT;

-- -----------------------------------------------------
-- Data for table `annuairev3`.`type_relation_eleve`
-- -----------------------------------------------------
START TRANSACTION;
USE `annuairev3`;
INSERT INTO `annuairev3`.`type_relation_eleve` (`id`, `description`, `libelle`) VALUES (1, 'Père', 'PERE');
INSERT INTO `annuairev3`.`type_relation_eleve` (`id`, `description`, `libelle`) VALUES (2, 'Mère', 'Mère');
INSERT INTO `annuairev3`.`type_relation_eleve` (`id`, `description`, `libelle`) VALUES (3, 'Tuteur', 'Tuteur');
INSERT INTO `annuairev3`.`type_relation_eleve` (`id`, `description`, `libelle`) VALUES (4, 'Autre membre de la famille','A_MMBR');
INSERT INTO `annuairev3`.`type_relation_eleve` (`id`, `description`, `libelle`) VALUES (5, 'Ddass', 'DDASS');
INSERT INTO `annuairev3`.`type_relation_eleve` (`id`, `description`, `libelle`) VALUES (6, 'Autre cas', 'A_CAS');
INSERT INTO `annuairev3`.`type_relation_eleve` (`id`, `description`, `libelle`) VALUES (7, 'Eleve lui meme', 'ELEVE');
COMMIT;
  
-- -----------------------------------------------------
-- Data for table `annuairev3`.`type_etablissement`
-- -----------------------------------------------------
START TRANSACTION;
USE `annuairev3`;
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf` ) VALUES ('Service du département', 'PU', NULL, 'SERVICE DU DEPARTEMENT');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Ecole', 'PR', 'Ecole privée', 'ECOLE');    
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Ecole', 'PU', 'Ecole publique','ECOLE');    
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Collège', 'PR',  'Collège privé','COLLEGE');    
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Collège', 'PU',  'Collège public','COLLEGE');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Lycée', 'PR',  'Lycée privé','LYCEE');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Lycée', 'PU',  'Lycée public','LYCEE');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Bâtiment', 'PU',  'Bâtiment public','LYCEE');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Lycée professionnel', 'PR',  'Lycée professionnel privé','LYCEE PROFESSIONEL');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Maison Familiale Rurale', 'PU', 'Maison Familiale Rurale','MAISON FAMILIALE RURALE');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('Campus', 'PU', 'Campus public','CAMPUS');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('CRDP', 'PU', 'Centre Régional de Documentation Pédagogique','CRDP');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ('CG Jeunes', 'PU', 'CG Jeunes','CG JEUNES');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ( 'Cité scolaire', 'PR', 'Cité scolaire privée','CITE SCOLAIRE');
INSERT INTO `annuairev3`.`type_etablissement` (`nom`, `type_contrat`, `libelle`, `type_struct_aaf`) VALUES ( 'Cité scolaire', 'PU', 'Cité scolaire publique','CITE SCOLAIRE');
COMMIT;
-- -----------------------------------------------------
-- Data for table `annuairev3`.`type_telephone`
-- -----------------------------------------------------
START TRANSACTION;
USE `annuairev3`;
INSERT INTO `annuairev3`.`type_telephone` (`id`, `libelle`, `description`) VALUES ('MAISON', 'Domicile', 'Numéro au domicile');
INSERT INTO `annuairev3`.`type_telephone` (`id`, `libelle`, `description`) VALUES ('PORTABLE', 'Portable', 'Numéro de portable');
INSERT INTO `annuairev3`.`type_telephone` (`id`, `libelle`, `description`) VALUES ('TRAVAIL', 'Travail', 'Numéro professionnel bureau');
INSERT INTO `annuairev3`.`type_telephone` (`id`, `libelle`, `description`) VALUES ('FAX', 'Fax', 'Numéro du fax ou téléphone/fax');
INSERT INTO `annuairev3`.`type_telephone` (`id`, `libelle`, `description`) VALUES ('AUTRE', 'Autre', 'Autre numéro de téléphone');

COMMIT;
