import sqlite3
import json
from datetime import datetime
from typing import List
import os

from summonsscraper.model import Case, Query, SearchQuery

CASES_DB = f"data{os.sep}case_data.db"


# Database Setup
def init_database():
    with sqlite3.connect(CASES_DB) as conn:
        cursor = conn.cursor()

        # Create queries table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS queries (
                id TEXT PRIMARY KEY,
                county TEXT NOT NULL,
                searches TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                status TEXT NOT NULL,
                step_function_arn TEXT
            )
        """)

        # Create cases table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS cases (
                caseId TEXT PRIMARY KEY,
                business TEXT NOT NULL,
                filingDate TEXT NOT NULL,
                defendant TEXT NOT NULL,
                caseName TEXT,
                loaded TEXT NOT NULL,
                caseStatus TEXT NOT NULL,
                addresses TEXT NOT NULL,
                other TEXT NOT NULL,
                query_id TEXT NOT NULL,
                user_status TEXT,
                FOREIGN KEY (query_id) REFERENCES queries (id)
            )
        """)

        conn.commit()


# Database Operations
def save_query(query: Query):
    with sqlite3.connect(CASES_DB) as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT OR REPLACE INTO queries 
            (id, county, searches, timestamp, status, step_function_arn)
            VALUES (?, ?, ?, ?, ?, ?)
        """,
            (
                query.id,
                query.county,
                json.dumps([s.dict() for s in query.searches]),
                query.timestamp.isoformat(),
                query.status,
                query.step_function_arn,
            ),
        )
        conn.commit()


def save_case(case: Case):
    with sqlite3.connect(CASES_DB) as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT OR REPLACE INTO cases 
            (caseId, business, filingDate, defendant, caseName, loaded, caseStatus, addresses, other, query_id, user_status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
            (
                case.caseId,
                case.business,
                case.filingDate.isoformat(),
                case.defendant,
                case.caseName,
                case.loaded.isoformat(),
                case.caseStatus,
                json.dumps(case.addresses),
                json.dumps(case.other),
                case.query_id,
                case.user_status,
            ),
        )
        conn.commit()


def get_all_cases() -> List[Case]:
    with sqlite3.connect(CASES_DB) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM cases")
        rows = cursor.fetchall()

    cases = []
    for row in rows:
        cases.append(
            Case(
                caseId=row[0],
                business=row[1],
                filingDate=datetime.fromisoformat(row[2]).date(),
                defendant=row[3],
                caseName=row[4],
                loaded=datetime.fromisoformat(row[5]).date(),
                caseStatus=row[6],
                addresses=json.loads(row[7]),
                other=json.loads(row[8]),
                query_id=row[9],
                user_status=row[10],
            )
        )

    return cases


def get_queries() -> List[Query]:
    with sqlite3.connect(CASES_DB) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM queries")
        rows = cursor.fetchall()

    queries = []
    for row in rows:
        searches = [SearchQuery(**s) for s in json.loads(row[2])]
        queries.append(
            Query(
                id=row[0],
                county=row[1],
                searches=searches,
                timestamp=datetime.fromisoformat(row[3]),
                status=row[4],
                step_function_arn=row[5],
            )
        )

    return queries


def update_case_user_status(case_id: str, status: str):
    with sqlite3.connect(CASES_DB) as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            UPDATE cases SET user_status = ? WHERE caseId = ?
        """,
            (status, case_id),
        )
        conn.commit()
