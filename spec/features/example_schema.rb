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

    test_database.create_table :source__PersonTyp do
      primary_key :Typ
      String :Bezeichnung
    end

    test_database.create_table :source__Adresse do
      primary_key :AdrKey
      String :Strasse
      String :Nummer
      Integer :PLZ
      String :Ort
    end

    test_database.create_table :source__Organisation do
      primary_key :OrgID
      String :Name
      String :Abteilung
      String :Adresse1StrNummer
      String :Adresse1Plz
      String :Adresse1Ort
      String :Adresse2StrNummer
      String :Adresse2Plz
      String :Adresse2Ort
    end

    test_database.create_table :source__Person do
      primary_key :PersID
      String :Vorname
      String :Nachname
      foreign_key :Firma, :source__Organisation
      foreign_key :Adresse, :source__Adresse
      foreign_key :Typ, :source__PersonTyp
    end

    test_database.create_table :source__Veranstaltung do
      primary_key :VeranstaltungId
      foreign_key :Organisation, :source__Organisation
    end

    test_database.create_table :source__Veranstaltungsbesucher do
      foreign_key :Veranstaltung, :source__Veranstaltung, null: false
      foreign_key :Besucher, :source__Person, null: false
    end
  end

  def drop_source_tables
    test_database.drop_schema :source, cascade: true
  end

  def create_target_tables
    test_database.create_table :addresses do
      primary_key :id
      String :external_id
      String :external_source
      String :line_1
      String :line_2
      String :line_3
      String :zip_code
      String :county
      String :country
    end

    test_database.create_table :organisations do
      primary_key :id
      String :external_id
      String :external_source
      String :name
      foreign_key :address_id, :addresses
    end

    test_database.create_table :departments do
      primary_key :id
      String :external_id
      String :external_source
      String :name
      foreign_key :organisation_id, :organisations
    end

    test_database.create_table :employees do
      primary_key :id
      String :external_id
      String :external_source
      String :firstname
      String :lastname
      TrueClass :manager
      foreign_key :organisation_id, :organisations
      foreign_key :department_id, :departments
      foreign_key :address_id, :addresses
    end

    test_database.create_table :customers do
      primary_key :id
      String :external_id
      String :external_source
      String :first_name
      String :last_name
      foreign_key :address_id, :addresses
    end

    test_database.create_table :events do
      primary_key :id
      String :external_id
      String :external_source
      String :name
      DateTime :start_datetime
      DateTime :end_datetime
      foreign_key :organisation, :organisations
    end

    test_database.create_join_table ({
      event_id: :events,
      customer_id: :customers
    })
  end

  def drop_target_tables
    test_database.drop_table :customers_events
    test_database.drop_table :events
    test_database.drop_table :customers
    test_database.drop_table :employees
    test_database.drop_table :departments
    test_database.drop_table :organisations
    test_database.drop_table :addresses
  end

end
