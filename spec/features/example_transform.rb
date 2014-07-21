import :organisations do
  query <<-SQL
    INSERT INTO #{stage_table} (
      name,
      external_id,
      external_source
    )
    SELECT
      o."Name",
      o."Name",
      '#{external_source}'

    FROM source."Organisation" o
  SQL
end

import :departments do
  references :organisations, on: :organisation_id

  query <<-SQL
    INSERT INTO #{stage_table} (
      name,
      external_id,
      external_source,
      external_organisation_id
    )
    SELECT
      o."Abteilung",
      #{combined_key('o."Name"', 'o."pkOrgId"')},
      '#{external_source}',
      o."Name"

    FROM source."Organisation" o
  SQL
end
