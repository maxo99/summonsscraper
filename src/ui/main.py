import streamlit as st
import pandas as pd
import uuid
from datetime import datetime, date
import asyncio

from core.database import get_all_cases, get_queries, init_database, save_case, save_query, update_case_user_status
from core.model import Case, Query, SearchQuery




# AWS Lambda Integration (Mock Implementation)
async def trigger_lambda_function(query: Query) -> str:
    """
    Trigger AWS Lambda function asynchronously
    Returns Step Function ARN for tracking
    """
    try:
        # Mock implementation - replace with actual AWS Lambda trigger
        lambda_payload = {
            "county": query.county,
            "searches": [s.model_dump() for s in query.searches],
        }
        assert lambda_payload

        # Simulate AWS Step Function ARN
        step_function_arn = (
            f"arn:aws:states:us-east-1:123456789:execution:case-processing:{query.id}"
        )

        # In real implementation, use boto3 to trigger Lambda
        # lambda_client = boto3.client('lambda')
        # response = lambda_client.invoke(
        #     FunctionName='your-lambda-function-name',
        #     InvocationType='Event',  # Asynchronous
        #     Payload=json.dumps(lambda_payload)
        # )

        return step_function_arn

    except Exception as e:
        st.error(f"Error triggering Lambda function: {str(e)}")
        return ''


# Streamlit App
def main():
    st.set_page_config(page_title="Case Data Management", layout="wide")
    st.markdown(
        """
        <style>
        [data-testid="stSidebar"] {
            min-width: 400px;
            max-width: 400px;
            width: 400px;
        }
        </style>
        """,
        unsafe_allow_html=True,
    )
    st.title("Case Data Management System")

    # Initialize database
    init_database()

    # Sidebar for submit query
    submit_query_sidebar()

    # Main content with tabs
    tab1, tab2 = st.tabs(["View Cases", "Query Status"])

    with tab1:
        view_cases_page()

    with tab2:
        query_status_page()


def submit_query_sidebar():
    st.sidebar.title("Submit New Query")

    # Initialize session state for business searches
    if "business_searches" not in st.session_state:
        st.session_state.business_searches = []
    if "editing_index" not in st.session_state:
        st.session_state.editing_index = None

    county = st.sidebar.text_input("County", placeholder="Enter county name")

    st.sidebar.subheader("Business Searches")

    # Display existing business searches
    if st.session_state.business_searches:
        for i, search in enumerate(st.session_state.business_searches):
            col1, col2 = st.sidebar.columns([3, 1])
            with col1:
                st.write(
                    f"**{i + 1}.** {search['business']} ({search['startDate']}{search['endDate']})"
                )
            with col2:
                if st.button("✏️", key=f"edit_{i}", help="Edit this search"):
                    st.session_state.editing_index = i
                    st.rerun()

    # Business search form (for adding new or editing existing)
    is_editing = st.session_state.editing_index is not None
    form_title = "Edit Business Search" if is_editing else "Add Business Search"

    with st.sidebar.form("business_form"):
        st.write(f"**{form_title}**")

        # Pre-populate form if editing
        if is_editing and get_editing_index() < len(
            st.session_state.business_searches
        ):
            edit_search = st.session_state.business_searches[
                get_editing_index()
            ]
            default_business = edit_search["business"]
            default_start = datetime.strptime(
                edit_search["startDate"], "%Y-%m-%d"
            ).date()
            default_end = datetime.strptime(edit_search["endDate"], "%Y-%m-%d").date()
        else:
            default_business = ""
            default_start = date.today()
            default_end = date.today()

        business = st.text_input("Business Name", value=default_business)
        start_date = st.date_input("Start Date", value=default_start)
        end_date = st.date_input("End Date", value=default_end)

        col1, col2 = st.columns(2)
        with col1:
            if st.form_submit_button("Save" if is_editing else "Add"):
                if business:
                    search_data = {
                        "business": business,
                        "startDate": start_date.strftime("%Y-%m-%d"),
                        "endDate": end_date.strftime("%Y-%m-%d"),
                    }

                    if is_editing:
                        st.session_state.business_searches[
                            get_editing_index()
                        ] = search_data
                        st.session_state.editing_index = None
                    else:
                        st.session_state.business_searches.append(search_data)

                    st.rerun()
                else:
                    st.error("Please enter a business name")

        with col2:
            if is_editing and st.form_submit_button("Cancel"):
                st.session_state.editing_index = None
                st.rerun()

    # Remove business search buttons
    if st.session_state.business_searches:
        st.sidebar.write("**Remove searches:**")
        for i, search in enumerate(st.session_state.business_searches):
            if st.sidebar.button(f"❌ Remove {search['business']}", key=f"remove_{i}"):
                st.session_state.business_searches.pop(i)
                if st.session_state.editing_index == i:
                    st.session_state.editing_index = None
                elif (
                    st.session_state.editing_index is not None
                    and st.session_state.editing_index > i
                ):
                    st.session_state.editing_index -= 1
                st.rerun()

    # Submit query button
    st.sidebar.divider()
    if st.sidebar.button(
        "Submit Query",
        type="primary",
        disabled=not (county and st.session_state.business_searches),
    ):
        if county and st.session_state.business_searches:
            # Convert to SearchQuery objects
            searches = [
                SearchQuery(**search) for search in st.session_state.business_searches
            ]
            query = Query(county=county, searches=searches)

            # Trigger AWS Lambda function
            with st.spinner("Triggering Lambda function..."):
                step_function_arn = asyncio.run(trigger_lambda_function(query))

                if step_function_arn:
                    query.step_function_arn = step_function_arn
                    query.status = "submitted"
                    save_query(query)

                    st.success("Query submitted successfully!")
                    st.info(f"Query ID: {query.id}")

                    # Clear the form
                    st.session_state.business_searches = []
                    st.session_state.editing_index = None
                    st.rerun()
                else:
                    st.error("Failed to submit query")
        else:
            st.error("Please fill in county and at least one business")

    # Display active queries at bottom of sidebar
    st.sidebar.divider()
    st.sidebar.subheader("Active Queries")

    queries = get_queries()
    active_queries = [
        q for q in queries if q.status in ["pending", "submitted", "processing"]
    ]

    if active_queries:
        st.sidebar.write(f"**{len(active_queries)} queries in progress:**")
        for query in active_queries:
            st.sidebar.write(f"• {query.county} - {query.status}")
    else:
        st.sidebar.write("No queries in progress")


def view_cases_page():
    st.header("View Cases")

    # Load cases
    cases = get_all_cases()

    if not cases:
        st.info("No cases found. Submit a query to load cases.")
        return

    # Convert to DataFrame
    cases_data = []
    for case in cases:
        cases_data.append(
            {
                "Case ID": case.caseId,
                "Business": case.business,
                "Filing Date": case.filingDate,
                "Defendant": case.defendant,
                "Case Name": case.caseName or "",
                "Case Status": case.caseStatus,
                "User Status": case.user_status or "None",
                "Loaded": case.loaded,
                "Addresses": ", ".join(case.addresses) if case.addresses else "",
                "Query ID": case.query_id,
            }
        )

    df = pd.DataFrame(cases_data)

    # Filters
    st.subheader("Filters")
    col1, col2, col3, col4 = st.columns(4)

    with col1:
        county_filter = st.selectbox(
            "County",
            ["All"] + list(df["Business"].unique()) if not df.empty else ["All"],
        )

    with col2:
        business_filter = st.selectbox(
            "Business",
            ["All"] + list(df["Business"].unique()) if not df.empty else ["All"],
        )

    with col3:
        status_filter = st.selectbox(
            "Case Status",
            ["All"] + list(df["Case Status"].unique()) if not df.empty else ["All"],
        )

    with col4:
        user_status_filter = st.selectbox(
            "User Status", ["All", "None", "sent", "response", "contract"]
        )

    # Apply filters
    filtered_df = df.copy()
    if business_filter != "All":
        filtered_df = filtered_df[filtered_df["Business"] == business_filter]
    if county_filter != "All":
        filtered_df = filtered_df[filtered_df["County"] == county_filter]
    if status_filter != "All":
        filtered_df = filtered_df[filtered_df["Case Status"] == status_filter]
    if user_status_filter != "All":
        if user_status_filter == "None":
            filtered_df = filtered_df[filtered_df["User Status"] == "None"]
        else:
            filtered_df = filtered_df[filtered_df["User Status"] == user_status_filter]
    
    
    # Display interactive dataframe with multi-row selection
    st.subheader(f"Cases ({len(filtered_df)} total)")

    if not filtered_df.empty:
        # Use dataframe with multi-row selection
        event = st.dataframe(
            filtered_df,
            use_container_width=True,
            hide_index=True,
            selection_mode="multi-row",
            on_select="rerun",
            key="cases_dataframe",
        )

        # Get selected cases
        selection = getattr(event, "selection", None) or event.get("selection") if isinstance(event, dict) else None
        selected_rows = selection.get("rows") if selection and isinstance(selection, dict) and "rows" in selection else []
        selected_cases = (
            [filtered_df.iloc[row]["Case ID"] for row in selected_rows]
            if selected_rows
            else []
        )

        if selected_cases:
            st.write(f"Selected {len(selected_cases)} cases")

            # Action buttons
            col1, col2, col3, col4 = st.columns(4)

            with col1:
                if st.button("Mark as Sent", disabled=not selected_cases):
                    for case_id in selected_cases:
                        update_case_user_status(case_id, "sent")
                    st.success(f"Marked {len(selected_cases)} cases as sent")
                    st.rerun()

            with col2:
                if st.button("Mark as Response", disabled=not selected_cases):
                    for case_id in selected_cases:
                        update_case_user_status(case_id, "response")
                    st.success(f"Marked {len(selected_cases)} cases as response")
                    st.rerun()

            with col3:
                if st.button("Mark as Contract", disabled=not selected_cases):
                    for case_id in selected_cases:
                        update_case_user_status(case_id, "contract")
                    st.success(f"Marked {len(selected_cases)} cases as contract")
                    st.rerun()

            with col4:
                if st.button("Reload Selected", disabled=not selected_cases):
                    # Create new query for selected cases
                    selected_case_objects = [
                        c for c in cases if c.caseId in selected_cases
                    ]
                    # Group by business and create reload query
                    st.info(
                        f"Reload functionality for {len(selected_case_objects)} cases would be triggered here"
                    )
        else:
            st.info("Select cases from the table above to perform actions")
    else:
        st.info("No cases match the current filters.")


def query_status_page():
    st.header("Query Status")

    queries = get_queries()

    if not queries:
        st.info("No queries found.")
        return

    # Display queries
    for query in queries:
        with st.expander(f"Query {query.id[:8]}... - {query.county} ({query.status})"):
            col1, col2 = st.columns(2)

            with col1:
                st.write(f"**County:** {query.county}")
                st.write(f"**Status:** {query.status}")
                st.write(f"**Timestamp:** {query.timestamp}")
                if query.step_function_arn:
                    st.write(f"**Step Function ARN:** {query.step_function_arn}")

            with col2:
                st.write("**Searches:**")
                for search in query.searches:
                    st.write(
                        f"- {search.business} ({search.startDate} to {search.endDate})"
                    )

            # Mock case loading (replace with actual Step Function status check)
            if st.button("Load Sample Cases", key=f"load_{query.id}"):
                # Generate sample cases for demonstration
                sample_cases = [
                    Case(
                        caseId=f"CASE_{uuid.uuid4().hex[:8]}",
                        business=search.business,
                        filingDate=datetime.strptime(
                            search.startDate, "%Y-%m-%d"
                        ).date(),
                        defendant=f"Defendant for {search.business}",
                        caseName=f"Case against {search.business}",
                        caseStatus="Active",
                        addresses=["123 Main St", "456 Oak Ave"],
                        query_id=query.id,
                    )
                    for search in query.searches
                ]

                for case in sample_cases:
                    save_case(case)

                st.success(f"Loaded {len(sample_cases)} sample cases")
                st.rerun()

def get_editing_index()-> int: 
    return st.session_state.editing_index


if __name__ == "__main__":
    main()
