defmodule HyperScheduleWeb.ScheduleControllerTest do
  use HyperScheduleWeb.ConnCase

  test "POST /api/v1/schedule", %{conn: conn} do
    conn =
      post(conn, "/api/v1/schedule", %{
        "dates" => [
          "2020-12-25",
          "2020-12-26",
          "2020-12-27",
          "2020-12-28"
        ],
        "participants" => [
          %{
            "name" => "Hiya",
            "blocked" => [
              "2020-12-26"
            ],
            "scheduled" => []
          },
          %{
            "name" => "Hiya2",
            "blocked" => [
              "2020-12-27"
            ],
            "scheduled" => []
          },
          %{
            "name" => "Hiya3",
            "blocked" => [
              "2020-12-28"
            ],
            "scheduled" => []
          }
        ]
      })

    assert json_response(conn, 200) == [
             %{
               "blocked" => ["2020-12-26"],
               "name" => "Hiya",
               "scheduled" => ["2020-12-25", "2020-12-28"]
             },
             %{
               "blocked" => ["2020-12-27"],
               "name" => "Hiya2",
               "scheduled" => ["2020-12-26"]
             },
             %{
               "blocked" => ["2020-12-28"],
               "name" => "Hiya3",
               "scheduled" => ["2020-12-27"]
             }
           ]
  end
end
