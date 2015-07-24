package api

import (
	"encoding/json"
	"strconv"
	"strings"
	"time"

	"github.com/extemporalgenome/slug"
	"github.com/icidasset/key-maps-api/db"
	"github.com/labstack/echo"
)

type Map struct {
	Id        int       `json:"id"`
	Slug      string    `json:"slug"`
	Name      string    `json:"name"`
	Structure string    `json:"structure"`
	Settings  string    `json:"settings"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	MapItems  IntSlice  `json:"map_items" db:"map_items"`
	UserId    int       `json:"-" db:"user_id"`
}

type MapSettings struct {
	SortBy          string `json:"sort_by"`
	IncludeJSONRoot bool   `json:"include_json_root"`
}

type MapFormData struct {
	Map Map `json:"map"`
}

type MapIndex struct {
	Maps     []Map     `json:"maps"`
	MapItems []MapItem `json:"map_items" db:"map_items"`
}

//
//  IntSlice
//
type IntSlice []int

func (i *IntSlice) Scan(src interface{}) error {
	as_bytes, _ := src.([]byte)
	as_string := string(as_bytes)

	a := strings.Split(as_string, ", ")
	b := make([]int, 0)

	for _, x := range a {
		i, _ := strconv.Atoi(x)
		b = append(b, i)
	}

	int_slice := IntSlice(b)

	if int_slice[0] == 0 {
		(*i) = nil
	} else {
		(*i) = int_slice
	}

	return nil
}

//
//  {get} INDEX
//
func Maps__Index(c *echo.Context) error {
	var maps []Map
	var map_items []MapItem
	var map_item_ids_i []int
	var map_item_ids_s []interface{}

	// execute query
	rows, err := db.Inst().Queryx(
		`SELECT maps.* AS map_id,
            array_to_string(array(
              SELECT id FROM map_items
              WHERE maps.id = map_items.map_id
            ), ', ') AS map_items
     FROM maps
     WHERE maps.user_id = $1
     ORDER BY maps.id`,
		c.Get("user").(User).Id,
	)

	// return if error
	if err != nil {
		return c.JSON(500, FormatError(err))
	}

	// scan rows
	for rows.Next() {
		m := Map{}
		err = rows.StructScan(&m)
		maps = append(maps, m)
	}

	// return if error
	if err != nil {
		return c.JSON(500, FormatError(err))
	}

	// gather map item ids
	for _, m := range maps {
		map_item_ids_i = append(map_item_ids_i, m.MapItems...)
	}

	for _, mii := range map_item_ids_i {
		map_item_ids_s = append(map_item_ids_s, strconv.Itoa(mii))
	}

	// map items
	items_query := "SELECT id, * FROM map_items WHERE id IN ("

	for i := 1; i <= len(map_item_ids_s); i++ {
		items_query += "$" + strconv.Itoa(i)
		if i < len(map_item_ids_s) {
			items_query += ", "
		}
	}

	items_query += ")"

	if len(map_item_ids_s) > 0 {
		err = db.Inst().Select(
			&map_items,
			items_query,
			map_item_ids_s...,
		)
	}

	// fallback
	if maps == nil {
		maps = []Map{}
	}
	if map_items == nil {
		map_items = []MapItem{}
	}

	// render
	if err != nil {
		return c.JSON(500, FormatError(err))
	} else {
		return c.JSON(200, MapIndex{Maps: maps, MapItems: map_items})
	}
}

//
//  {get} SHOW
//
func Maps__Show(c *echo.Context) error {
	m := Map{}

	// execute query
	err := db.Inst().Get(
		&m,
		`SELECT * FROM maps WHERE id = $1 AND user_id = $2`,
		c.Param("id"),
		c.Get("user").(User).Id,
	)

	// render
	if err != nil {
		if IsNoResultsError(err.Error()) {
			return c.JSON(404, nil)
		} else {
			return c.JSON(500, FormatError(err))
		}
	} else if m.Id == 0 {
		return c.JSON(404, nil)
	} else {
		return c.JSON(200, map[string]Map{"map": m})
	}
}

//
//  {post} CREATE
//
func Maps__Create(c *echo.Context) error {
	query := `INSERT INTO maps (name, slug, structure, settings, created_at, updated_at, user_id) VALUES (:name, :slug, :structure, :settings, :created_at, :updated_at, :user_id) RETURNING id`

	// parse json from request body
	mfd := MapFormData{}
	json_decoder := json.NewDecoder(c.Request().Body)
	json_decoder.Decode(&mfd)

	// make new map
	slug := slug.Slug(mfd.Map.Name)
	now := time.Now()

	new_map := Map{Name: mfd.Map.Name, Slug: slug, Structure: mfd.Map.Structure, Settings: mfd.Map.Settings, CreatedAt: now, UpdatedAt: now, UserId: c.Get("user").(User).Id}

	// execute query
	rows, err := db.Inst().NamedQuery(query, new_map)

	// return if error
	if err != nil {
		return c.JSON(500, FormatError(err))
	}

	// scan rows
	for rows.Next() {
		err = rows.StructScan(&new_map)
	}

	// render
	if err != nil {
		return c.JSON(500, FormatError(err))
	} else {
		return c.JSON(201, map[string]Map{"map": new_map})
	}
}

//
//  {put} UPDATE
//
func Maps__Update(c *echo.Context) error {
	mfd := MapFormData{}
	json_decoder := json.NewDecoder(c.Request().Body)
	json_decoder.Decode(&mfd)

	// update map
	_, err := db.Inst().Exec(
		`UPDATE maps
     SET structure = $1, settings = $2, updated_at = $3
     WHERE id = $4 AND user_id = $5`,
		mfd.Map.Structure,
		mfd.Map.Settings,
		time.Now(),
		c.Param("id"),
		c.Get("user").(User).Id,
	)

	// return if error
	if err != nil {
		return c.JSON(500, FormatError(err))
	}

	// fetch
	m := Map{}

	err = db.Inst().Get(
		&m,
		`SELECT * FROM maps WHERE id = $1 AND user_id = $2`,
		c.Param("id"),
		c.Get("user").(User).Id,
	)

	// render
	if err != nil {
		return c.JSON(500, FormatError(err))
	} else {
		return c.JSON(200, map[string]Map{"map": m})
	}
}

//
//  {delete} DESTROY
//
func Maps__Destroy(c *echo.Context) error {
	var err_delete_a error
	var err_delete_b error

	// delete related map items
	_, err_delete_b = db.Inst().Exec(
		`DELETE FROM map_items
     WHERE map_id = $1 AND map_id IN (SELECT id FROM maps WHERE user_id = $2)`,
		c.Param("id"),
		c.Get("user").(User).Id,
	)

	// delete map
	_, err_delete_a = db.Inst().Exec(
		`DELETE FROM maps WHERE id = $1 AND user_id = $2`,
		c.Param("id"),
		c.Get("user").(User).Id,
	)

	// render
	if err_delete_b != nil {
		return c.JSON(500, FormatError(err_delete_b))
	} else if err_delete_a != nil {
		return c.JSON(500, FormatError(err_delete_a))
	} else {
		return c.JSON(204, nil)
	}
}
