--
-- Table of formatters
--

-- NOTE: Rows in this table should only be maintained (i.e., inserted
-- or updated) using the formatter_upsert() function.
-- TODO: Use native upserting when Pg is upgraded to 9.5


DO $$
DECLARE
    t_name TEXT;            -- Name of the table being worked on
    t_version INTEGER;      -- Current version of the table
    t_version_old INTEGER;  -- Version of the table at the start
BEGIN

    --
    -- Preparation
    --

    t_name := 'formatter';

    t_version := table_version_find(t_name);
    t_version_old := t_version;


    --
    -- Upgrade Blocks
    --

    -- Version 0 (nonexistant) to version 1
    IF t_version = 0
    THEN

        CREATE TABLE formatter (

        	-- Row identifier
        	id		BIGSERIAL
        			PRIMARY KEY,

        	-- Original JSON
        	json		JSONB
        			NOT NULL,

        	-- Formatter Name
        	name		TEXT
        			UNIQUE NOT NULL,

        	-- Verbose description
        	description	TEXT,

        	-- When this record was last updated
        	updated		TIMESTAMP WITH TIME ZONE,

        	-- Whether or not the formatterr is currently available
        	available	BOOLEAN
        			DEFAULT TRUE
        );


        CREATE INDEX formatter_name ON formatter(name);

	t_version := t_version + 1;

    END IF;

    -- Version 1 to version 2
    -- ...
    -- IF t_version = 1
    -- THEN
    --     ...
    -- 
    --     t_version := t_version + 1;
    -- END IF;


    --
    -- Cleanup
    --

    PERFORM table_version_set(t_name, t_version, t_version_old);

END;
$$ LANGUAGE plpgsql;



DROP TRIGGER IF EXISTS formatter_alter ON formatter CASCADE;

DO $$ BEGIN PERFORM drop_function_all('formatter_alter'); END $$;

CREATE OR REPLACE FUNCTION formatter_alter()
RETURNS TRIGGER
AS $$
DECLARE
    json_result TEXT;
BEGIN
    json_result := json_validate(NEW.json, '#/pScheduler/PluginEnumeration/Formatter');
    IF json_result IS NOT NULL
    THEN
        RAISE EXCEPTION 'Invalid enumeration: %', json_result;
    END IF;

    NEW.name := NEW.json ->> 'name';
    NEW.description := NEW.json ->> 'description';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER formatter_alter
BEFORE INSERT OR UPDATE
ON formatter
FOR EACH ROW
    EXECUTE PROCEDURE formatter_alter();




-- Insert a new formatter or update an existing one by name

DO $$ BEGIN PERFORM drop_function_all('formatter_upsert'); END $$;

CREATE OR REPLACE FUNCTION formatter_upsert(new_json JSONB)
RETURNS VOID
AS $$
DECLARE
    existing_id BIGINT;
    new_name TEXT;
BEGIN

   new_name := (new_json ->> 'name')::TEXT;

   SELECT id from formatter into existing_id WHERE name = new_name;

   IF NOT FOUND THEN

      -- Legitimately-new row.
      INSERT INTO formatter (json, updated, available)
      VALUES (new_json, now(), true);

   ELSE

     -- Update of existing row.
     UPDATE formatter
     SET
       json = new_json,
       updated = now(),
       available = true
     WHERE id = existing_id;

   END IF;

END;
$$ LANGUAGE plpgsql;




-- Function to run at startup.

DO $$ BEGIN PERFORM drop_function_all('formatter_boot'); END $$;

CREATE OR REPLACE FUNCTION formatter_boot()
RETURNS VOID
AS $$
DECLARE
    run_result external_program_result;
    formatter_list JSONB;
    formatter_name TEXT;
    formatter_enumeration JSONB;
    json_result TEXT;
    sschema NUMERIC;  -- Name dodges a reserved word
BEGIN
    run_result := pscheduler_command(ARRAY['internal', 'list', 'formatter']);
    IF run_result.status <> 0 THEN
       RAISE EXCEPTION 'Unable to list installed formatters: %', run_result.stderr;
    END IF;

    formatter_list := run_result.stdout::JSONB;

    FOR formatter_name IN (select * from jsonb_array_elements_text(formatter_list))
    LOOP

	run_result := pscheduler_command(ARRAY['internal', 'invoke', 'formatter', formatter_name, 'enumerate']);
        IF run_result.status <> 0 THEN
            RAISE WARNING 'Formatter "%" failed to enumerate: %',
	        formatter_name, run_result.stderr;
            CONTINUE;
        END IF;

	formatter_enumeration := run_result.stdout::JSONB;

        sschema := text_to_numeric(formatter_enumeration ->> 'schema');
        IF sschema IS NOT NULL AND sschema > 1 THEN
            RAISE WARNING 'Formatter "%": schema % is not supported',
                formatter_name, sschema;
            CONTINUE;
        END IF;

        json_result := json_validate(formatter_enumeration,
	    '#/pScheduler/PluginEnumeration/Formatter');
        IF json_result IS NOT NULL
        THEN
            RAISE WARNING 'Invalid enumeration for formatter "%": %', formatter_name, json_result;
	    CONTINUE;
        END IF;


	PERFORM formatter_upsert(formatter_enumeration);

    END LOOP;

    -- TODO: Disable, but don't remove, formatters that aren't installed.
    UPDATE formatter SET available = FALSE WHERE updated < now();
    -- TODO: Should also can anything on the schedule that used this formatter.  (Do that elsewhere.)
END;
$$ LANGUAGE plpgsql;



-- Validate an formatter entry and raise an error if invalid.

DO $$ BEGIN PERFORM drop_function_all('formatter_validate'); END $$;

CREATE OR REPLACE FUNCTION formatter_validate(
    candidate JSONB
)
RETURNS VOID
AS $$
DECLARE
    formatter_name TEXT;
    candidate_data JSONB;
    run_result external_program_result;
    validate_result JSONB;
BEGIN
    IF NOT candidate ? 'formatter' THEN
        RAISE EXCEPTION 'No formatter name specified in formatter.';
    END IF;

    formatter_name := candidate ->> 'formatter';

    IF NOT EXISTS (SELECT * FROM formatter WHERE name = formatter_name) THEN
        RAISE EXCEPTION 'No formatter "%" is avaiable.', formatter_name;
    END IF;

    IF candidate ? 'data' THEN
        candidate_data := candidate -> 'data';
    ELSE
        candidate_data := 'null'::JSONB;
    END IF;

    run_result := pscheduler_command(ARRAY['internal', 'invoke', 'formatter',
    	       formatter_name, 'data-is-valid'], candidate_data::TEXT );
    IF run_result.status <> 0 THEN
        RAISE EXCEPTION 'Formatter "%" failed to validate: %', formatter_name, run_result.stderr;
    END IF;

    validate_result := run_result.stdout::JSONB;

    IF NOT (validate_result ->> 'valid')::BOOLEAN THEN
        IF validate_result ? 'error' THEN
            RAISE EXCEPTION 'Invalid data for formatter "%": %', formatter_name, validate_result ->> 'error';
        ELSE
            RAISE EXCEPTION 'Invalid data for formatter "%": No error provided by plugin.', formatter_name;
        END IF;
    END IF;

END;
$$ LANGUAGE plpgsql;
