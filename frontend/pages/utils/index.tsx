import axios from "axios";

export async function subgraphQuery(query: any) {
  try {
    // Replace YOUR-SUBGRAPH-URL with the url of your subgraph
    const SUBGRAPH_URL = "https://api.studio.thegraph.com/query/79049/obsidian-graph/version/latest";
    const response = await axios.post(SUBGRAPH_URL, {
      query,
    });
    if (response.data.errors) {
      console.error(response.data.errors);
      throw new Error(`Error making subgraph query ${response.data.errors}`);
    }
    return response.data.data;
  } catch (error: any) {
    console.error(error);
    throw new Error(`Could not query the subgraph ${error.message}`);
  }
}