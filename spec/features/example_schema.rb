module ExampleSchema

  def create_tables
    create_source_tables
    create_target_tables
  end

  def drop_tables
    drop_source_tables
    drop_target_tables
  end

  def create_source_tables
    test_database.create_schema :source

    test_database.create_table :source__Organisation do
      Integer :pkOrgId
      String :Name
      String :Abteilung
    end

    test_database.create_table :source__Person do
      Integer :pkPersID
      String :Vorname
      String :Nachname
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

  def create_target_tables

    test_database.create_table :organisations do
      primary_key :id
      String :external_id
      String :external_source
      String :name
      DateTime :created_at
      DateTime :deleted_at
    end

    test_database.create_table :departments do
      primary_key :id
      String :external_id
      String :external_source
      String :name
      foreign_key :organisation_id, :organisations
      DateTime :created_at
      DateTime :deleted_at
    end

    test_database.create_table :attendees do
      primary_key :id
      String :external_id
      String :external_source
      String :first_name
      String :last_name
      DateTime :created_at
      DateTime :deleted_at
    end

    test_database.create_table :events do
      primary_key :id
      String :external_id
      String :external_source
      String :name
      DateTime :start_datetime
      DateTime :end_datetime
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
