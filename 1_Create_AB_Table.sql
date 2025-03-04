-- Create the POSTGIS extension if required
CREATE EXTENSION  IF NOT EXISTS postgis;

-- Create the destination schema if required
CREATE SCHEMA IF NOT EXISTS os_address;

--DROP TABLE IF IT EXISTS ALREADY
DROP TABLE IF EXISTS os_address.addressbase CASCADE;


-- Create a function which will populate the full_address and geom columns as
-- data are imported

CREATE OR REPLACE FUNCTION create_geom_and_address()
        RETURNS TRIGGER
AS
        $$
BEGIN
        -- The geometry
        -- Set it based on the x_coord and y_coord fields, or latitude and longitude. Comment/uncomment as necessary.
        -- NEW.geom = ST_SetSRID(ST_MakePoint(NEW.LONGITUDE, NEW.LATITUDE), 4258);
        NEW.geom = ST_SetSRID(ST_MakePoint(NEW.X_COORDINATE, NEW.Y_COORDINATE), 27700);
        -- The full address
        -- Initialise it
        NEW.full_address = '';
        -- Build the full address by only including optional address components if they
        -- exist
        IF NEW.RM_ORGANISATION_NAME IS NOT NULL
                AND
                LENGTH(NEW.RM_ORGANISATION_NAME) > 0 THEN
                NEW.full_address                 = NEW.full_address
                || NEW.RM_ORGANISATION_NAME
                || ', ';
        END IF;
        IF NEW.department_name IS NOT NULL
                AND
                LENGTH(NEW.department_name) > 0 THEN
                NEW.full_address            = NEW.full_address
                || NEW.department_name
                || ', ';
        END IF;
        IF NEW.po_box_number IS NOT NULL
                AND
                LENGTH(NEW.po_box_number) > 0 THEN
                NEW.full_address          = NEW.full_address
                || NEW.po_box_number
                || ', ';
        END IF;
        IF NEW.sub_building_name IS NOT NULL
                AND
                LENGTH(NEW.sub_building_name) > 0 THEN
                NEW.full_address              = NEW.full_address
                || NEW.sub_building_name
                || ', ';
        END IF;
        IF NEW.building_name IS NOT NULL
                AND
                LENGTH(NEW.building_name) > 0 THEN
                NEW.full_address          = NEW.full_address
                || NEW.building_name
                || ', ';
        END IF;
        IF NEW.building_number IS NOT NULL THEN
                NEW.full_address = NEW.full_address
                || NEW.building_number
                || ', ';
        END IF;
        IF NEW.sao_text IS NOT NULL
                AND
                LENGTH(NEW.sao_text) > 0
                AND
                LENGTH(NEW.sub_building_name) = 0
                AND
                LENGTH(NEW.building_name) = 0 THEN
                NEW.full_address          = NEW.full_address
                || NEW.sao_text
                || ', ';
        END IF;
        IF NEW.pao_text IS NOT NULL
                AND
                LENGTH(NEW.pao_text) > 0
                AND
                LENGTH(NEW.sub_building_name) = 0
                AND
                LENGTH(NEW.building_name) = 0 THEN
                NEW.full_address          = NEW.full_address
                || NEW.pao_text
                || ', ';
        END IF;
        IF NEW.pao_start_number IS NOT NULL
                AND
                LENGTH(NEW.pao_start_suffix) > 0
                AND
                LENGTH(NEW.building_name) = 0
                AND
                NEW.building_number IS NULL THEN
                NEW.full_address = NEW.full_address
                || NEW.pao_start_number
                || NEW.pao_start_suffix
                || ', ';
        END IF;
        IF NEW.pao_start_number IS NOT NULL
                AND
                LENGTH(NEW.pao_start_suffix) = 0
                AND
                LENGTH(NEW.building_name) = 0
                AND
                NEW.building_number IS NULL THEN
                NEW.full_address = NEW.full_address
                || NEW.pao_start_number
                || ', ';
        END IF;
        IF NEW.street_description IS NOT NULL
                AND
                LENGTH(NEW.street_description) > 0 THEN
                NEW.full_address               = NEW.full_address
                || NEW.street_description
                || ', ';
        END IF;
        NEW.full_address = NEW.full_address
        || NEW.town_name
        || ', ';
        IF NEW.double_dependent_locality IS NOT NULL
                AND
                LENGTH(NEW.double_dependent_locality) > 0 THEN
                NEW.full_address                      = NEW.full_address
                || NEW.double_dependent_locality
                || ', ';
        END IF;
        IF NEW.dependent_locality IS NOT NULL
                AND
                LENGTH(NEW.dependent_locality) > 0 THEN
                NEW.full_address               = NEW.full_address
                || NEW.dependent_locality
                || ', ';
        END IF;
        NEW.full_address = NEW.full_address
        || NEW.postcode_locator;
        RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TABLE
        os_address.addressbase
        (
                id serial NOT NULL                                                        ,
                UPRN                            bigint NOT NULL                           ,
                UDPRN                           INT NULL                                  ,
                CHANGE_TYPE                     CHAR(1) NOT NULL                          ,
                STATE                           INT NULL                                  ,
                STATE_DATE                      DATE NULL                                 ,
                CLASS                           CHAR(6) NOT NULL                          ,
                PARENT_UPRN                     bigint NULL                               ,
                X_COORDINATE                    FLOAT NULL                                ,
                Y_COORDINATE                    FLOAT NULL                                ,
                LATITUDE                        FLOAT NOT NULL                            ,
                LONGITUDE                       FLOAT NOT NULL                            ,
                RPC                             INT NOT NULL                              ,
                LOCAL_CUSTODIAN_CODE            SMALLINT NOT NULL                         ,
                COUNTRY                         CHAR(1) NOT NULL                          ,
                LA_START_DATE                   DATE NOT NULL                             ,
                LAST_UPDATE_DATE                DATE NOT NULL                             ,
                ENTRY_DATE                      DATE NOT NULL                             ,
                RM_ORGANISATION_NAME            VARCHAR(60) NOT NULL                      ,
                LA_ORGANISATION                 VARCHAR(100) NULL                         ,
                DEPARTMENT_NAME                 VARCHAR(60) NULL                          ,
                LEGAL_NAME                      VARCHAR(60) NULL                          ,
                SUB_BUILDING_NAME               VARCHAR(30) NULL                          ,
                BUILDING_NAME                   VARCHAR(50) NULL                          ,
                BUILDING_NUMBER                 SMALLINT NULL                             ,
                SAO_START_NUMBER                SMALLINT NULL                             ,
                SAO_START_SUFFIX                CHAR(2) NULL                              ,
                SAO_END_NUMBER                  SMALLINT NULL                             ,
                SAO_END_SUFFIX                  VARCHAR(2) NULL                           ,
                SAO_TEXT                        VARCHAR(90) NULL                          ,
                ALT_LANGUAGE_SAO_TEXT           VARCHAR(90) NULL                          ,
                PAO_START_NUMBER                SMALLINT NULL                             ,
                PAO_START_SUFFIX                CHAR(2) NULL                              ,
                PAO_END_NUMBER                  SMALLINT NULL                             ,
                PAO_END_SUFFIX                  CHAR(2) NULL                              ,
                PAO_TEXT                        VARCHAR(90) NULL                          ,
                ALT_LANGUAGE_PAO_TEXT           VARCHAR(90) NULL                          ,
                USRN                            INT NOT NULL                              ,
                USRN_MATCH_INDICATOR            INT NOT NULL                              ,
                AREA_NAME                       VARCHAR(40) NULL                          ,
                LEVEL                           VARCHAR(30) NULL                          ,
                OFFICIAL_FLAG                   CHAR(1) NULL                              ,
                OS_ADDRESS_TOID                 VARCHAR(20) NULL                          ,
                OS_ADDRESS_TOID_VERSION         SMALLINT NULL                             ,
                OS_ROADLINK_TOID                VARCHAR(20) NULL                          ,
                OS_ROADLINK_TOID_VERSION        SMALLINT NULL                             ,
                OS_TOPO_TOID                    VARCHAR(20) NULL                          ,
                OS_TOPO_TOID_VERSION            SMALLINT NULL                             ,
                VOA_CT_RECORD                   bigint NULL                               ,
                VOA_NDR_RECORD                  bigint NULL                               ,
                STREET_DESCRIPTION              VARCHAR(100) NOT NULL                     ,
                ALT_LANGUAGE_STREET_DESCRIPTION VARCHAR(100) NULL                         ,
                DEPENDENT_THOROUGHFARE          VARCHAR(80) NULL                          ,
                THOROUGHFARE                    VARCHAR(80) NULL                          ,
                WELSH_DEPENDENT_THOROUGHFARE    VARCHAR(80) NULL                          ,
                WELSH_THOROUGHFARE              VARCHAR(80) NULL                          ,
                DOUBLE_DEPENDENT_LOCALITY       VARCHAR(35) NULL                          ,
                DEPENDENT_LOCALITY              VARCHAR(35) NULL                          ,
                LOCALITY                        VARCHAR(35) NULL                          ,
                WELSH_DEPENDENT_LOCALITY        VARCHAR(35) NULL                          ,
                WELSH_DOUBLE_DEPENDENT_LOCALITY VARCHAR(35) NULL                          ,
                TOWN_NAME                       VARCHAR(30) NULL                          ,
                ADMINISTRATIVE_AREA             VARCHAR(30) NOT NULL                      ,
                POST_TOWN                       VARCHAR(35) NULL                          ,
                WELSH_POST_TOWN                 VARCHAR(30) NULL                          ,
                POSTCODE                        CHAR(8) NULL                              ,
                POSTCODE_LOCATOR                CHAR(8) NOT NULL                          ,
                POSTCODE_TYPE                   CHAR(1) NULL                              ,
                DELIVERY_POINT_SUFFIX           CHAR(2) NULL                              ,
                ADDRESSBASE_POSTAL              CHAR(1) NOT NULL                          ,
                PO_BOX_NUMBER                   VARCHAR(6) NULL                           ,
                WARD_CODE                       VARCHAR(9) NULL                           ,
                PARISH_CODE                     VARCHAR(9) NULL                           ,
                RM_START_DATE                   DATE NULL                                 ,
                MULTI_OCC_COUNT                 SMALLINT NULL                             ,
                VOA_NDR_P_DESC_CODE             CHAR(5) NULL                              ,
                VOA_NDR_SCAT_CODE               CHAR(4) NULL                              ,
                ALT_LANGUAGE                    CHAR(3) NULL                              ,
                full_address                    text COLLATE pg_catalog."default" NOT NULL,
                geom geometry(Point,27700) NOT NULL                                        ,
                CONSTRAINT addressbase_pkey PRIMARY KEY (id)
        )
        WITH
        (
                OIDS=FALSE
        );


		
-- trigger to create points and addresses
-- This trigger will be executed on each row inserted, calling the function defined above
CREATE TRIGGER
        tr_create_geom_and_address BEFORE
INSERT
ON
        os_address.addressbase FOR EACH ROW EXECUTE PROCEDURE create_geom_and_address();


