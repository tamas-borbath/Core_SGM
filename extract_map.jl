### A Pluto.jl notebook ###
# v0.19.20

using Markdown
using InteractiveUtils

# ╔═╡ 4f2b65e0-d156-11ed-3212-eb5cf51bffe8
using JSON, DataFrames, Gumbo, XLSX, Dates

# ╔═╡ 1f97ae01-53b8-4a4d-acf4-ed907e5cb7cd
json = JSON.parsefile("./JAO/Map/map_data.json")

# ╔═╡ 6ba95824-bc09-470d-8ab5-90fb8912b40d
function get_circle_params(p_circles)
	params = DataFrame(Latitude = p_circles["args"][1], Longitude = p_circles["args"][2], Size =  p_circles["args"][3], Stroke = p_circles["args"][6]["stroke"], fillColor = p_circles["args"][6]["fillColor"], Color = p_circles["args"][6]["color"], label = p_circles["args"][9], popup = p_circles["args"][11])
end

# ╔═╡ 06bc7418-94f9-4ff3-bd02-e9dfb2826f1a
function export_to_xlsx(p_path, export_stack)
		XLSX.openxlsx(p_path, mode="w") do xf
        XLSX.rename!(xf[1], "Cache info")
		r_settings_df = DataFrame(Export_time = [now()])
        XLSX.writetable!(xf[1], collect(DataFrames.eachcol(r_settings_df)), 		DataFrames.names(r_settings_df))
        for (name,df) in export_stack
            sheet = XLSX.addsheet!(xf, string(name))
            XLSX.writetable!(sheet, collect(DataFrames.eachcol(df)), DataFrames.names(df))
        end
    end
end

# ╔═╡ 76d229e9-fd10-4031-ab4b-ef393777eb72
md"""## Transformers layer"""

# ╔═╡ 32777c04-687b-4db0-a7de-ce5fdbc64862
function parse_popup_xf(p_label)
	parsed =  parsehtml(p_label)
	TR_Name = string(parsed.root[2][1][1])[8:end]
	EIC_Code = string(parsed.root[2][3][2][1])[2:end]
	return TR_Name, EIC_Code
end

# ╔═╡ b8830047-7529-4a4b-8579-f8c8fb6b44a5
function parse_label_xf(p_label)
	parsed =  parsehtml(p_label) 
	resistance = parse(Float64,string(parsed.root[2][3][2][3][1][2][1][1]))
	reactance = parse(Float64,string(parsed.root[2][3][2][3][1][2][2][1]))
	if string(parsed.root[2][3][2][3][1][2][3]) == "<td align=\"right\"></td>"
		Susceptance = missing
	else
		Susceptance = parse(Float64,string(parsed.root[2][3][2][3][1][2][3][1]))
	end
	if string(parsed.root[2][3][2][3][1][2][4]) == "<td align=\"right\"></td>"
		Conductance = missing
	else
		Conductance = parse(Float64,string(parsed.root[2][3][2][3][1][2][4][1]))
	end
	return resistance, reactance, Susceptance, Conductance
end

# ╔═╡ 7591ec7e-edb0-4d54-b899-7cf9b0ba6240
function parse_xf(p_method)
	g_transformers = get_circle_params(p_method)
	g_transformers[!,:Name] .= ""
	g_transformers[!,:EIC] .= ""
	g_transformers[!,:Resistance] .= 0.0
	g_transformers[!,:Reactance] .= 0.0
	g_transformers[!,:Susceptance] .= 0.0
	g_transformers[!,:Conductance] .= 0.0
	allowmissing!(g_transformers)
	for row in eachrow(g_transformers)
		row[:Name],row[:EIC] = parse_popup_xf(row[:popup])
		row[:Resistance], row[:Reactance], row[:Susceptance], row[:Conductance] =	parse_label_xf(row[:label])
	end
	g_transformers[:, Not([:popup, :label])]
end

# ╔═╡ 0594e2e9-1394-487f-947f-0ab4eb5a75ec
md"""## Substations"""

# ╔═╡ 70ed9a07-96d5-4a8d-89e9-5dbedbbda5f9
function parse_subs(p_method)
	g_subs = get_circle_params(p_method)
	return g_subs[:, Not([:popup, :label])]
end

# ╔═╡ 47378a2f-b6f8-46f2-8298-025a6060a674
md"""### Lines"""

# ╔═╡ 149fd131-1382-4ac2-ae2e-f83a03c8853b
function return_coords(p_coords)
	@assert length(p_coords[1][1]["lat"]) == 2
	p_coords[1][1]["lat"][1], p_coords[1][1]["lng"][1], p_coords[1][1]["lng"][2], p_coords[1][1]["lat"][2]
end

# ╔═╡ d099c813-2a4b-4470-b173-73bb95458ab5
function parse_popup_lines(p_label)
	parsed =  parsehtml(p_label)
	Name = string(parsed.root[2][1][1])[10:end]
	EIC = string(parsed.root[2][3][2][1])

	Resistance = parse(Float64,string(parsed.root[2][3][2][3][1][2][1][1]))
	Reactance = parse(Float64,string(parsed.root[2][3][2][3][1][2][2][1]))
	if string(parsed.root[2][3][2][3][1][2][3]) == "<td align=\"right\"></td>"
		Susceptance = missing
	else
		Susceptance = parse(Float64,string(parsed.root[2][3][2][3][1][2][3][1]))
	end
	
	if string(parsed.root[2][3][2][3][1][2][4]) == "<td align=\"right\"></td>"
		Length = missing
	else
		Length = parse(Float64,string(parsed.root[2][3][2][3][1][2][4][1]))
	end
	return Name, EIC, Resistance, Reactance, Susceptance, Length
end

# ╔═╡ 3de182ee-4cd7-46fd-9a67-5053078577eb
function parse_lines(p_method)
	Lines = DataFrame(Color = p_method["args"][4]["color"])
	Lines[!, :Longitude_f] .= 0.0
	Lines[!, :Latitude_f] .= 0.0
	Lines[!, :Longitude_t] .= 0.0
	Lines[!, :Latitude_t] .= 0.0
	Lines[!, :Name] .= ""
	Lines[!, :EIC] .= ""
	Lines[!, :Resistance] .= 0.0
	Lines[!, :Reactance] .= 0.0
	Lines[!, :Susceptance] .= 0.0
	Lines[!, :Length] .= 0.0
	allowmissing!(Lines)
	for i in 1:size(Lines)[1]
		Lines[i, :Longitude_f],Lines[i, :Latitude_f], Lines[i, :Longitude_t],Lines[i, :Latitude_t] = return_coords(p_method["args"][1][i])
		Lines[i, :Name], Lines[i, :EIC], Lines[i, :Resistance], Lines[i, :Reactance], Lines[i, :Susceptance], Lines[i, :Length] = parse_popup_lines(p_method["args"][5][i])
	end
	return Lines
end

# ╔═╡ ff93e7f2-d39a-4f08-b2be-7c7ea0623c64
function process_calls(p_calls)
	export_stack = []
	for p_method in p_calls
		if p_method["method"] == "addCircleMarkers"
			if p_method["args"][5] == "Transformers"
				push!(export_stack, ("XF", parse_xf(p_method)))
			elseif p_method["args"][5] == "Substations"
				push!(export_stack, ("Substations", parse_subs(p_method)))
			end
		elseif p_method["method"] == "addPolylines"
			if p_method["args"][3] == "Lines"
				push!(export_stack, ("Lines", parse_lines(p_method)))
			end
		else
		@show  p_method["method"]
		end
	end
	return export_stack
end

# ╔═╡ 96eae725-ddd5-4bbf-98c0-4b0aee2a4852
map_elements = process_calls(json["x"]["calls"])

# ╔═╡ 37621851-d2ca-4a3b-a749-b8a386b5dbc3
export_to_xlsx("map_elements.xlsx",map_elements )

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
Gumbo = "708ec375-b3d6-5a57-a7ce-8257bf98657a"
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
XLSX = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"

[compat]
DataFrames = "~1.5.0"
Gumbo = "~0.8.2"
JSON = "~0.21.3"
XLSX = "~0.9.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.3"
manifest_format = "2.0"
project_hash = "da0c17eec26a749b326ebfe05c6656137f392dd4"

[[deps.AbstractTrees]]
git-tree-sha1 = "faa260e4cb5aba097a73fab382dd4b5819d8ec8c"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "7a60c856b9fa189eb34f5f8a6f6b5529b7942957"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.6.1"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "aa51303df86f8626a962fccb878430cdb0a97eee"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.5.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Gumbo]]
deps = ["AbstractTrees", "Gumbo_jll", "Libdl"]
git-tree-sha1 = "a1a138dfbf9df5bace489c7a9d5196d6afdfa140"
uuid = "708ec375-b3d6-5a57-a7ce-8257bf98657a"
version = "0.8.2"

[[deps.Gumbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "29070dee9df18d9565276d68a596854b1764aa38"
uuid = "528830af-5a63-567c-a44a-034ed33b8444"
version = "0.10.2+0"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "478ac6c952fddd4399e71d4779797c538d0ff2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.8"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "548793c7859e28ef026dba514752275ee871169f"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "77d3c4726515dca71f6d80fbb5e251088defe305"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.18"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.XLSX]]
deps = ["Artifacts", "Dates", "EzXML", "Printf", "Tables", "ZipFile"]
git-tree-sha1 = "d6af50e2e15d32aff416b7e219885976dc3d870f"
uuid = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"
version = "0.9.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "f492b7fe1698e623024e873244f10d89c95c340a"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.10.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╠═4f2b65e0-d156-11ed-3212-eb5cf51bffe8
# ╠═1f97ae01-53b8-4a4d-acf4-ed907e5cb7cd
# ╠═6ba95824-bc09-470d-8ab5-90fb8912b40d
# ╠═ff93e7f2-d39a-4f08-b2be-7c7ea0623c64
# ╠═96eae725-ddd5-4bbf-98c0-4b0aee2a4852
# ╠═37621851-d2ca-4a3b-a749-b8a386b5dbc3
# ╠═06bc7418-94f9-4ff3-bd02-e9dfb2826f1a
# ╟─76d229e9-fd10-4031-ab4b-ef393777eb72
# ╠═32777c04-687b-4db0-a7de-ce5fdbc64862
# ╠═b8830047-7529-4a4b-8579-f8c8fb6b44a5
# ╠═7591ec7e-edb0-4d54-b899-7cf9b0ba6240
# ╟─0594e2e9-1394-487f-947f-0ab4eb5a75ec
# ╠═70ed9a07-96d5-4a8d-89e9-5dbedbbda5f9
# ╟─47378a2f-b6f8-46f2-8298-025a6060a674
# ╠═3de182ee-4cd7-46fd-9a67-5053078577eb
# ╠═149fd131-1382-4ac2-ae2e-f83a03c8853b
# ╠═d099c813-2a4b-4470-b173-73bb95458ab5
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
