#!/usr/bin/env julia
"""
Knowledge Base SQLite Query Engine
Replaces JSON file reads with SQLite queries

Author: Morpheus
Created: 2026-04-03 23:54 UTC
"""

using SQLite
using JSON

const DB_PATH = joinpath(dirname(@__DIR__), "..", "data", "morpheus.db")

"""
    search_kb(query::String; limit::Int=10)::Vector{Dict}

Full-text search across all KB documents.
Returns matching documents ranked by relevance.
"""
function search_kb(query::String; limit::Int=10)::Vector{Dict}
    try
        db = SQLite.DB(DB_PATH)
        
        # Full-text search
        results = DBInterface.execute(db,
            """
            SELECT 
                d.id, 
                d.name, 
                d.category,
                substr(d.content, 1, 200) as preview,
                rank
            FROM kb_search
            JOIN kb_documents d ON kb_search.rowid = d.rowid
            WHERE kb_search MATCH ?
            ORDER BY rank ASC
            LIMIT ?
            """,
            [query, limit]
        ) |> Tables.columntable
        
        # Convert to Vector of Dicts
        docs = []
        for i in 1:length(results.id)
            push!(docs, Dict(
                "id" => results.id[i],
                "name" => results.name[i],
                "category" => results.category[i],
                "preview" => results.preview[i]
            ))
        end
        
        return docs
        
    catch e
        @warn "KB search failed: $e"
        return []
    end
end

"""
    get_kb_document(doc_id::String)::Dict

Retrieve full KB document by ID.
"""
function get_kb_document(doc_id::String)::Dict
    try
        db = SQLite.DB(DB_PATH)
        
        result = DBInterface.execute(db,
            """
            SELECT id, name, category, content, created_at, file_size
            FROM kb_documents
            WHERE id = ?
            """,
            [doc_id]
        ) |> Tables.columntable
        
        if length(result.id) == 0
            return Dict("error" => "Document not found: $doc_id")
        end
        
        # Parse content JSON
        content = JSON.parse(result.content[1])
        
        return Dict(
            "id" => result.id[1],
            "name" => result.name[1],
            "category" => result.category[1],
            "content" => content,
            "created_at" => result.created_at[1],
            "file_size" => result.file_size[1]
        )
        
    catch e
        return Dict("error" => "Failed to retrieve document: $e")
    end
end

"""
    list_kb_documents(category::String="")::Vector{Dict}

List all KB documents, optionally filtered by category.
"""
function list_kb_documents(category::String="")::Vector{Dict}
    try
        db = SQLite.DB(DB_PATH)
        
        if isempty(category)
            results = DBInterface.execute(db,
                """
                SELECT id, name, category, file_size, created_at
                FROM kb_documents
                ORDER BY created_at DESC
                """
            ) |> Tables.columntable
        else
            results = DBInterface.execute(db,
                """
                SELECT id, name, category, file_size, created_at
                FROM kb_documents
                WHERE category = ?
                ORDER BY created_at DESC
                """,
                [category]
            ) |> Tables.columntable
        end
        
        docs = []
        for i in 1:length(results.id)
            push!(docs, Dict(
                "id" => results.id[i],
                "name" => results.name[i],
                "category" => results.category[i],
                "file_size" => results.file_size[i],
                "created_at" => results.created_at[i]
            ))
        end
        
        return docs
        
    catch e
        @warn "List KB documents failed: $e"
        return []
    end
end

"""
    search_kb_by_tag(tag::String; limit::Int=10)::Vector{Dict}

Search KB documents by tag.
"""
function search_kb_by_tag(tag::String; limit::Int=10)::Vector{Dict}
    try
        db = SQLite.DB(DB_PATH)
        
        results = DBInterface.execute(db,
            """
            SELECT DISTINCT d.id, d.name, d.category
            FROM kb_documents d
            JOIN kb_document_tags dt ON d.id = dt.document_id
            JOIN kb_tags t ON dt.tag_id = t.id
            WHERE LOWER(t.tag_name) LIKE LOWER(?)
            LIMIT ?
            """,
            ["%$tag%", limit]
        ) |> Tables.columntable
        
        docs = []
        for i in 1:length(results.id)
            push!(docs, Dict(
                "id" => results.id[i],
                "name" => results.name[i],
                "category" => results.category[i]
            ))
        end
        
        return docs
        
    catch e
        @warn "Tag search failed: $e"
        return []
    end
end

"""
    kb_stats()::Dict

Get KB statistics (total docs, tags, size, etc).
"""
function kb_stats()::Dict
    try
        db = SQLite.DB(DB_PATH)
        
        # Count documents
        doc_count = DBInterface.execute(db, "SELECT COUNT(*) FROM kb_documents") |> Tables.columntable
        
        # Count tags
        tag_count = DBInterface.execute(db, "SELECT COUNT(*) FROM kb_tags") |> Tables.columntable
        
        # Total size
        size_result = DBInterface.execute(db, "SELECT SUM(file_size) FROM kb_documents") |> Tables.columntable
        
        return Dict(
            "total_documents" => doc_count.COUNT_ASTERISK[1],
            "total_tags" => tag_count.COUNT_ASTERISK[1],
            "total_size_bytes" => size_result.SUM_file_size_[1] === nothing ? 0 : size_result.SUM_file_size_[1],
            "database_path" => DB_PATH,
            "status" => "operational"
        )
        
    catch e
        return Dict("error" => "Failed to get KB stats: $e")
    end
end

# Main: CLI interface
if abspath(PROGRAM_FILE) == @__FILE__
    import ArgParse
    
    parser = ArgParse.ArgumentParser()
    ArgParse.add_argument!(parser, "command", help="KB command: search, get, list, tags, stats")
    ArgParse.add_argument!(parser, "--query", help="Search query")
    ArgParse.add_argument!(parser, "--id", help="Document ID")
    ArgParse.add_argument!(parser, "--category", help="Filter by category")
    ArgParse.add_argument!(parser, "--tag", help="Search by tag")
    ArgParse.add_argument!(parser, "--limit", type=Int, default=10, help="Result limit")
    
    args = ArgParse.parse_args(parser)
    
    if args["command"] == "search" && !isnothing(args["query"])
        results = search_kb(args["query"]; limit=args["limit"])
        println(JSON.json(results, 2))
        
    elseif args["command"] == "get" && !isnothing(args["id"])
        result = get_kb_document(args["id"])
        println(JSON.json(result, 2))
        
    elseif args["command"] == "list"
        category = get(args, "category", "")
        results = list_kb_documents(category)
        println(JSON.json(results, 2))
        
    elseif args["command"] == "tags" && !isnothing(args["tag"])
        results = search_kb_by_tag(args["tag"]; limit=args["limit"])
        println(JSON.json(results, 2))
        
    elseif args["command"] == "stats"
        stats = kb_stats()
        println(JSON.json(stats, 2))
        
    else
        println("Unknown command or missing arguments")
        println("Usage:")
        println("  kb-query-sqlite.jl search --query 'term'")
        println("  kb-query-sqlite.jl get --id 'doc_id'")
        println("  kb-query-sqlite.jl list [--category 'category']")
        println("  kb-query-sqlite.jl tags --tag 'tag_name'")
        println("  kb-query-sqlite.jl stats")
    end
end
