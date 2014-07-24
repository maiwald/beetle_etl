module ExampleSchema

  def create_tables
    create_source_tables
    create_stage_tables
    create_target_tables
  end

  def drop_tables
    drop_source_tables
    drop_stage_tables
    drop_target_tables
  end

  def create_source_tables
    test_database.create_schema :source

    test_database.create_table :source__Organisation do
      Integer :pkOrgId
      String :Name, size: 255
      String :Abteilung, size: 255
    end

    test_database.create_table :source__Person do
      Integer :pkPersID
      String :Vorname, size: 255
      String :Nachname, size: 255
      Integer :fkFirma
      Integer :fkAdresse
      Integer :fkTyp
    end

    test_database.create_table :source__Veranstaltung do
      Integer :pkVeranstaltungId
      Integer :fkOrganisation
    end

    test_database.create_table :source__Veranstaltungsbesuch do
      Integer :fkVeranstaltung
      Integer :fkBesucher
    end
  end

  def drop_source_tables
    test_database.drop_schema :source, cascade: true
  end

  def create_stage_tables
    test_database.create_schema :stage

    test_database.create_table :stage__import_runs do
      primary_key :id
      DateTime :started_at
      DateTime :finished_at
      String :state, size: 255
    end

    test_database.create_table :stage__organisations do
      Integer :id
      String :external_id, size: 255
      foreign_key :import_run_id, :stage__import_runs
      index [:external_id, :import_run_id]
      String :transition, size: 255

      String :name, size: 255
    end

    test_database.create_table :stage__departments do
      Integer :id
      String :external_id, size: 255
      foreign_key :import_run_id, :stage__import_runs
      index [:external_id, :import_run_id]
      String :transition, size: 255

      String :name, size: 255

      String :external_organisation_id, size: 255
      Integer :organisation_id

    end

    test_database.create_table :stage__attendees do
      Integer :id
      String :external_id, size: 255
      foreign_key :import_run_id, :stage__import_runs
      index [:external_id, :import_run_id]
      String :transition, size: 255

      String :first_name, size: 255
      String :last_name, size: 255
    end

    test_database.create_table :stage__events do
      Integer :id
      String :external_id, size: 255
      foreign_key :import_run_id, :stage__import_runs
      index [:external_id, :import_run_id]
      String :transition, size: 255

      String :name, size: 255
      DateTime :starts_at
      DateTime :ends_at

      String :external_organisations_id, size: 255
      Integer :organisation_id
    end

    test_database.create_table :stage__attendees_events do
      Integer :id
      String :external_id, size: 255
      foreign_key :import_run_id, :stage__import_runs
      index [:external_id, :import_run_id]
      String :transition, size: 255

      String :external_attendee_id, size: 255
      Integer :attendee_id

      String :external_event_id, size: 255
      Integer :event_id
    end
  end

  def drop_stage_tables
    test_database.drop_schema :stage, cascade: true
  end

  def create_target_tables
    test_database.create_table :organisations do
      primary_key :id
      String :external_id, size: 255
      String :external_source, size: 255
      String :name, size: 255
      DateTime :created_at
      DateTime :deleted_at
    end

    test_database.create_table :departments do
      primary_key :id
      String :external_id, size: 255
      String :external_source, size: 255
      String :name, size: 255
      foreign_key :organisation_id, :organisations
      DateTime :created_at
      DateTime :deleted_at
    end

    test_database.create_table :attendees do
      primary_key :id
      String :external_id, size: 255
      String :external_source, size: 255
      String :first_name, size: 255
      String :last_name, size: 255
      DateTime :created_at
      DateTime :deleted_at
    end

    test_database.create_table :events do
      primary_key :id
      String :external_id, size: 255
      String :external_source, size: 255
      String :name, size: 255
      DateTime :starts_at
      DateTime :ends_at
      foreign_key :organisation, :organisations
      DateTime :created_at
      DateTime :deleted_at
    end

    test_database.create_table :attendees_events do
      foreign_key :attendee_id, :attendees, null: false
      foreign_key :event_id, :events, null: false
      primary_key [:attendee_id, :event_id]
      index [:attendee_id, :event_id]
    end
  end

  def drop_target_tables
    test_database.drop_table :attendees_events
    test_database.drop_table :events
    test_database.drop_table :attendees
    test_database.drop_table :departments
    test_database.drop_table :organisations
  end

end
