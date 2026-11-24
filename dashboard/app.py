"""
Streamlit interactive dashboard.
"""

from pathlib import Path
from importlib import import_module

import streamlit as st

st.set_page_config(
    page_title="DATA 201 | Purchase Analytics",
    layout="wide",
)

st.title("Amazon Purchase Analytics")
st.caption("DATA 201 · Group 3 | Customer purchase analysis")

members = ["Manomay", "Mourya", "Kashif", "Waqas"]

available = [
    member
    for member in members
    if (Path(__file__).parent / member / "dashboard.py").is_file()
]

if not available:
    st.warning("No dashboard modules are available.")
else:
    page = st.sidebar.radio("Analysis section", available)
    st.sidebar.caption("Visualizations use the team's MySQL database.")

    try:
        module = import_module(f"{page}.dashboard")
        module.render()
    except Exception as err:
        st.error("Could not load this dashboard section.")
        st.caption(f"Diagnostic: {type(err).__name__}: {err}")
